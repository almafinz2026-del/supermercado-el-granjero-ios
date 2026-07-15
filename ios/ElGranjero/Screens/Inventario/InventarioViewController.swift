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

        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProducto))
        navigationItem.rightBarButtonItem = addBtn

        searchBar.delegate = self
        searchBar.placeholder = "Buscar producto..."
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let p = filtered[indexPath.row]
        let name = p["nombre"] as? String ?? "?"
        let stock = p["stock_actual"] as? Int ?? 0
        let price = FirebaseService.formatMoney(p["precio_venta"] as? Double ?? 0)
        cell.textLabel?.text = "\(name) - \(price) (Stock: \(stock))"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.backgroundColor = .white
        cell.accessoryType = .disclosureIndicator
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
}
