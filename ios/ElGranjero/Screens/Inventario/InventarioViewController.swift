import UIKit

class InventarioViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private var productos: [[String: Any]] = []
    private var filtered: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        title = "Inventario"

        let s = UIBarButtonItem(image: UIImage(systemName: "barcode.viewfinder"), style: .plain, target: self, action: #selector(openScanner))
        let a = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProducto))
        navigationItem.rightBarButtonItems = [a, s]

        searchBar.delegate = self
        searchBar.placeholder = "Buscar producto..."
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(InventarioProductCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func loadData() {
        Task {
            do {
                productos = try await fb.getList("productos")
                filtered = productos
                tableView.reloadData()
            } catch { print("Error: \(error)") }
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        if text.isEmpty { filtered = productos }
        else { filtered = productos.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) || ($0["codigo"] as? String ?? "").localizedCaseInsensitiveContains(text) } }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? InventarioProductCell else {
            return UITableViewCell()
        }
        let p = filtered[indexPath.row]
        cell.configure(with: p)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showProductoForm(filtered[indexPath.row])
    }

    @objc private func addProducto() { showProductoForm(nil) }

    private func showProductoForm(_ producto: [String: Any]?) {
        let alert = UIAlertController(title: producto == nil ? "Nuevo Producto" : "Editar Producto", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Nombre"; tf.text = producto?["nombre"] as? String }
        alert.addTextField { tf in tf.placeholder = "Código"; tf.text = producto?["codigo"] as? String; tf.autocapitalizationType = .none }
        alert.addTextField { tf in tf.placeholder = "Precio compra"; tf.text = producto?["precio_compra"] != nil ? "\(producto!["precio_compra"]!)" : ""; tf.keyboardType = .decimalPad }
        alert.addTextField { tf in tf.placeholder = "Precio venta"; tf.text = producto?["precio_venta"] != nil ? "\(producto!["precio_venta"]!)" : ""; tf.keyboardType = .decimalPad }
        alert.addTextField { tf in tf.placeholder = "Stock actual"; tf.text = producto?["stock_actual"] != nil ? "\(producto!["stock_actual"]!)" : ""; tf.keyboardType = .numberPad }
        alert.addTextField { tf in tf.placeholder = "Stock mínimo"; tf.text = producto?["stock_minimo"] != nil ? "\(producto!["stock_minimo"]!)" : ""; tf.keyboardType = .numberPad }
        alert.addTextField { tf in tf.placeholder = "Marca"; tf.text = producto?["marca"] as? String }
        alert.addTextField { tf in tf.placeholder = "Categoría"; tf.text = producto?["categoria"] as? String }

        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let f = alert.textFields ?? []
            guard let name = f[0].text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else { return }
            var data: [String: Any] = [
                "nombre": name, "codigo": f[1].text ?? "",
                "precio_compra": Double(f[2].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0,
                "precio_venta": Double(f[3].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0,
                "stock_actual": Int(f[4].text ?? "") ?? 0,
                "stock_minimo": Int(f[5].text ?? "") ?? 0,
                "marca": f[6].text ?? "", "categoria": f[7].text ?? ""
            ]
            if let id = producto?["id"] as? Int { data["id"] = id }
            Task {
                do {
                    if producto == nil { data["id"] = FirebaseService.nextId(in: self.productos); try await self.fb.addToList("productos", item: data) }
                    else { try await self.fb.updateInList("productos", idValue: data["id"]!, updates: data) }
                    self.loadData()
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        if producto != nil {
            alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
                guard let self = self, let id = producto?["id"] as? Int else { return }
                Task { do { try await self.fb.removeFromList("productos", idValue: id); self.loadData() } catch { print("Error: \(error)") } }
            })
        }
        present(alert, animated: true)
    }

    @objc private func openScanner() {
        present(BarcodeScannerViewController { [weak self] code in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let p = self.productos.first(where: { ($0["codigo"] as? String) == code }) {
                    self.showProductoForm(p)
                } else {
                    let a = UIAlertController(title: "Nuevo", message: "Código: \(code)\n¿Crear producto?", preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "Crear", style: .default) { [weak self] _ in
                        self?.showProductoForm(["codigo": code])
                    })
                    a.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
                    self.present(a, animated: true)
                }
            }
        }, animated: true)
    }
}

// MARK: - Inventario Product Cell
class InventarioProductCell: UITableViewCell {
    private let cardView = UIView()
    private let nameLabel = UILabel()
    private let detailsLabel = UILabel()
    private let stockPill = UIView()
    private let stockLabel = UILabel()
    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .darkText
        nameLabel.numberOfLines = 1
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nameLabel)
        
        detailsLabel.font = .systemFont(ofSize: 11)
        detailsLabel.textColor = .gray
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(detailsLabel)
        
        stockPill.layer.cornerRadius = 6
        stockPill.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stockPill)
        
        stockLabel.font = .systemFont(ofSize: 9, weight: .bold)
        stockLabel.textAlignment = .center
        stockLabel.translatesAutoresizingMaskIntoConstraints = false
        stockPill.addSubview(stockLabel)
        
        priceLabel.font = .systemFont(ofSize: 16, weight: .bold)
        priceLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(priceLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            
            detailsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailsLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            detailsLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -8),
            
            stockPill.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 6),
            stockPill.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            stockPill.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            stockPill.heightAnchor.constraint(equalToConstant: 18),
            
            stockLabel.leadingAnchor.constraint(equalTo: stockPill.leadingAnchor, constant: 8),
            stockLabel.trailingAnchor.constraint(equalTo: stockPill.trailingAnchor, constant: -8),
            stockLabel.centerYAnchor.constraint(equalTo: stockPill.centerYAnchor),
            
            priceLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
        ])
    }
    
    func configure(with p: [String: Any]) {
        let name = p["nombre"] as? String ?? ""
        let brand = p["marca"] as? String ?? ""
        let cat = p["categoria"] as? String ?? ""
        let stock = p["stock_actual"] as? Int ?? 0
        let minStock = p["stock_minimo"] as? Int ?? 0
        let price = p["precio_venta"] as? Double ?? 0
        
        nameLabel.text = name
        priceLabel.text = FirebaseService.formatMoney(price)
        
        let details = [brand, cat].filter { !$0.isEmpty }.joined(separator: " • ")
        detailsLabel.text = details.isEmpty ? "Sin categoría" : details
        
        if stock <= minStock {
            stockPill.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1)
            stockLabel.textColor = .systemRed
            stockLabel.text = stock == 0 ? "AGOTADO" : "BAJO STOCK: \(stock)"
        } else {
            stockPill.backgroundColor = UIColor(red: 0.9, green: 0.96, blue: 0.92, alpha: 1)
            stockLabel.textColor = UIColor(red: 0.1, green: 0.48, blue: 0.28, alpha: 1)
            stockLabel.text = "STOCK: \(stock)"
        }
    }
}
