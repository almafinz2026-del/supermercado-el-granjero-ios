import UIKit

class ComprasViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var compras: [[String: Any]] = []
    private var productos: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1); title = "Compras"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(nuevaCompra))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear; tableView.separatorStyle = .none; tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() {
        Task {
            do {
                async let c = fb.getList("compras"); async let p = fb.getList("productos")
                (compras, productos) = try await (c, p); tableView.reloadData()
            } catch { print("Error: \(error)") }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { compras.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = compras[indexPath.row]; cell.textLabel?.numberOfLines = 2
        let total = FirebaseService.formatMoney(c["total"] as? Double ?? 0)
        let prov = c["proveedor"] as? String ?? "?"
        let items = c["items"] as? [[String: Any]] ?? []
        let iva = c["iva"] as? Double ?? 0
        let fecha = (c["fecha"] as? String ?? "").prefix(10)
        cell.textLabel?.text = "\(prov)\n\(items.count) items | IVA \(Int(iva))% | \(total) | \(fecha)"
        cell.textLabel?.font = .systemFont(ofSize: 12); cell.backgroundColor = .white
        cell.layer.cornerRadius = 8; cell.layer.masksToBounds = true; cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 56 }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { tableView.deselectRow(at: indexPath, animated: true) }

    @objc private func nuevaCompra() {
        showCompraForm(compra: nil)
    }

    private func showCompraForm(compra existing: [String: Any]?) {
        var items = existing?["items"] as? [[String: Any]] ?? []
        let isEdit = existing != nil
        let alert = UIAlertController(title: isEdit ? "Editar Compra" : "Nueva Compra", message: "\n\n\n\n\n", preferredStyle: .alert)
        let wid: CGFloat = 270

        // Proveedor
        let provTF = UITextField(); provTF.placeholder = "Proveedor"; provTF.borderStyle = .roundedRect; provTF.font = .systemFont(ofSize: 14)
        provTF.frame = CGRect(x: 8, y: 10, width: wid - 16, height: 32); alert.view.addSubview(provTF)
        if let p = existing?["proveedor"] as? String { provTF.text = p }

        // IVA
        let ivaTF = UITextField(); ivaTF.placeholder = "IVA %"; ivaTF.borderStyle = .roundedRect; ivaTF.keyboardType = .decimalPad; ivaTF.font = .systemFont(ofSize: 14)
        ivaTF.frame = CGRect(x: 8, y: 48, width: wid - 16, height: 32); alert.view.addSubview(ivaTF)
        if let iv = existing?["iva"] as? Double { ivaTF.text = "\(iv)" } else { ivaTF.text = "0" }

        // Items button
        let itemsBtn = UIButton(type: .system); itemsBtn.setTitle(items.isEmpty ? "+ Agregar Productos" : "\(items.count) producto(s) - toca para editar", for: .normal)
        itemsBtn.titleLabel?.font = .systemFont(ofSize: 13); itemsBtn.frame = CGRect(x: 8, y: 86, width: wid - 16, height: 32)
        itemsBtn.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            alert.dismiss(animated: true) {
                self.showItemPicker(currentItems: items) { picked in
                    items = picked; self.showCompraForm(compra: existing)
                }
            }
        }, for: .touchUpInside)
        alert.view.addSubview(itemsBtn)

        // Pagado toggle
        let pagadoLabel = UILabel(); pagadoLabel.text = "Pagado de Caja:"; pagadoLabel.font = .systemFont(ofSize: 13)
        pagadoLabel.frame = CGRect(x: 8, y: 124, width: 150, height: 28); alert.view.addSubview(pagadoLabel)
        let pagadoSw = UISwitch(); pagadoSw.frame = CGRect(x: wid - 70, y: 120, width: 51, height: 31)
        pagadoSw.isOn = existing?["pagado"] as? Bool ?? false; alert.view.addSubview(pagadoSw)

        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self, let prov = provTF.text?.trimmingCharacters(in: .whitespaces), !prov.isEmpty else { return }
            let iva = Double(ivaTF.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            let total = items.reduce(0.0) { s, i in
                let q = Double(i["cantidad"] as? Int ?? 0); let p = i["precio_compra"] as? Double ?? 0; return s + q * p
            }
            Task {
                do {
                    var data: [String: Any] = ["proveedor": prov, "total": total, "iva": iva, "pagado": pagadoSw.isOn, "items": items, "fecha": FirebaseService.nowString()]
                    if let eid = existing?["id"] as? Int {
                        data["id"] = eid; try await self.fb.updateInList("compras", idValue: eid, updates: data)
                    } else {
                        data["id"] = FirebaseService.nextId(in: self.compras); try await self.fb.addToList("compras", item: data)
                    }
                    // Update product stock & prices
                    for it in items {
                        if let pid = it["producto_id"] as? Int {
                            let prods = try await self.fb.getList("productos")
                            if var prod = prods.first(where: { ($0["id"] as? Int) == pid }) {
                                let qty = it["cantidad"] as? Int ?? 0; let cost = it["precio_compra"] as? Double ?? 0
                                let newStock = (prod["stock_actual"] as? Int ?? 0) + qty
                                var up: [String: Any] = ["stock_actual": newStock, "precio_compra": cost]
                                if let pv = it["precio_venta"] as? Double { up["precio_venta"] = pv }
                                try await self.fb.updateInList("productos", idValue: pid, updates: up)
                            }
                        }
                    }
                    // Deduct from caja if pagado
                    if pagadoSw.isOn, let abierta = (try await self.fb.getList("cajas")).first(where: { ($0["estado"] as? String) == "abierta" }), let cid = abierta["id"] as? Int {
                        let egresos = (abierta["egresos"] as? Double ?? 0) + total
                        try await self.fb.updateInList("cajas", idValue: cid, updates: ["egresos": egresos])
                    }
                    self.loadData()
                } catch { print("Error save compra: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func showItemPicker(currentItems: [[String: Any]], completion: @escaping ([[String: Any]]) -> Void) {
        let vc = CompraItemPickerVC(productos: productos, items: currentItems, onDone: completion)
        let nav = UINavigationController(rootViewController: vc); nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController { sheet.detents = [.large()] }
        present(nav, animated: true)
    }
}

// MARK: - Item Picker
class CompraItemPickerVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var allProds: [[String: Any]] = []
    private var filtered: [[String: Any]] = []
    private var selected: [[String: Any]] = [] // current cart
    private let onDone: ([[String: Any]]) -> Void

    init(productos: [[String: Any]], items: [[String: Any]], onDone: @escaping ([[String: Any]]) -> Void) {
        self.allProds = productos; self.filtered = productos; self.selected = items; self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Productos de la Compra"; view.backgroundColor = UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Listo (\(selected.count))", style: .done, target: self, action: #selector(doneTapped))

        searchBar.delegate = self; searchBar.placeholder = "Buscar producto..."
        searchBar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(searchBar)

        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "icell")
        tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        if text.isEmpty { filtered = allProds } else {
            filtered = allProds.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) || ($0["codigo"] as? String ?? "").localizedCaseInsensitiveContains(text) }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "icell", for: indexPath)
        let p = filtered[indexPath.row]; let pid = p["id"] as? Int ?? 0; let name = p["nombre"] as? String ?? "?"
        let stock = p["stock_actual"] as? Int ?? 0; let cost = FirebaseService.formatMoney(p["precio_compra"] as? Double ?? 0)
        if let existing = selected.first(where: { ($0["producto_id"] as? Int) == pid }) {
            let q = existing["cantidad"] as? Int ?? 0; cell.textLabel?.text = "✓ \(name) — x\(q)" }
        else { cell.textLabel?.text = "\(name) — Stock: \(stock) | \(cost)" }
        cell.textLabel?.font = .systemFont(ofSize: 12); cell.backgroundColor = .white; cell.accessoryType = .detailButton
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let p = filtered[indexPath.row]; let pid = p["id"] as? Int ?? 0; let name = p["nombre"] as? String ?? "?"
        let alert = UIAlertController(title: name, message: "Precio compra: \(FirebaseService.formatMoney(p["precio_compra"] as? Double ?? 0))", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Cantidad"; tf.keyboardType = .numberPad; tf.text = "1" }
        alert.addTextField { tf in tf.placeholder = "Precio Compra"; tf.keyboardType = .decimalPad; tf.text = "\(p["precio_compra"] as? Double ?? 0)" }
        alert.addTextField { tf in tf.placeholder = "Precio Venta"; tf.keyboardType = .decimalPad; tf.text = "\(p["precio_venta"] as? Double ?? 0)" }
        alert.addAction(UIAlertAction(title: "Agregar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let q = Int(alert.textFields?[0].text ?? "") ?? 1
            let pc = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            let pv = Double(alert.textFields?[2].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            if let idx = self.selected.firstIndex(where: { ($0["producto_id"] as? Int) == pid }) { self.selected.remove(at: idx) }
            self.selected.append(["producto_id": pid, "nombre": name, "cantidad": q, "precio_compra": pc, "precio_venta": pv])
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItem?.title = "Listo (\(self.selected.count))"
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let p = filtered[indexPath.row]; let pid = p["id"] as? Int ?? 0
        if editingStyle == .delete, let idx = selected.firstIndex(where: { ($0["producto_id"] as? Int) == pid }) {
            selected.remove(at: idx); tableView.reloadData(); navigationItem.rightBarButtonItem?.title = "Listo (\(selected.count))"
        }
    }
    @objc private func doneTapped() { dismiss(animated: true) { self.onDone(self.selected) } }
}
