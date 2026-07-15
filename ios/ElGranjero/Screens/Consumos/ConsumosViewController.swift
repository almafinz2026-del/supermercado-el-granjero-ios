import UIKit

class ConsumosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var consumos: [[String: Any]] = []
    private var productos: [[String: Any]] = []
    private let fb = FirebaseService.shared

    private var tempProductoId: Int? = nil
    private var tempProductoNombre = ""
    private var tempCantidad = "1"
    private var tempFecha = FirebaseService.todayString()
    private var tempMotivo = ""
    private var editingConsumo: [String: Any]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground; title = "Consumos Propios"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addConsumo))
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); loadData() }

    private func loadData() {
        Task { do {
            async let c = fb.getList("autoconsumos")
            async let p = fb.getList("productos")
            (consumos, productos) = try await (c, p)
            tableView.reloadData()
        } catch { print("Error: \(error)") } }
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { consumos.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = consumos[indexPath.row]
        let prod = c["producto_nombre"] as? String ?? "?"
        let cant = c["cantidad"] as? Int ?? 0
        let fecha = c["fecha"] as? String ?? ""
        let motivo = c["motivo"] as? String ?? ""
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.text = "\(prod) — Unidades: \(cant) | \(fecha)\nMotivo: \(motivo)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12); cell.backgroundColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editConsumo(consumos[indexPath.row])
    }

    // MARK: - Actions
    @objc private func addConsumo() {
        tempProductoId = nil; tempProductoNombre = ""; tempCantidad = "1"
        tempFecha = FirebaseService.todayString(); tempMotivo = ""; editingConsumo = nil
        showForm()
    }

    private func editConsumo(_ c: [String: Any]) {
        editingConsumo = c; tempProductoId = c["producto_id"] as? Int
        tempProductoNombre = c["producto_nombre"] as? String ?? ""
        tempCantidad = "\(c["cantidad"] as? Int ?? 1)"
        tempFecha = c["fecha"] as? String ?? FirebaseService.todayString()
        tempMotivo = c["motivo"] as? String ?? ""
        showForm()
    }

    // MARK: - Form
    private func showForm() {
        let alert = UIAlertController(title: editingConsumo == nil ? "Nuevo Consumo" : "Editar Consumo", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        let wid: CGFloat = 270

        let prodLabel = UILabel(); prodLabel.text = "Producto:"; prodLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        prodLabel.frame = CGRect(x: 8, y: 8, width: 65, height: 20); alert.view.addSubview(prodLabel)

        let prodBtn = UIButton(type: .system)
        prodBtn.setTitle(tempProductoNombre.isEmpty ? "Seleccionar Producto" : tempProductoNombre, for: .normal)
        prodBtn.contentHorizontalAlignment = .left; prodBtn.titleLabel?.font = .systemFont(ofSize: 13); prodBtn.titleLabel?.lineBreakMode = .byTruncatingTail
        prodBtn.setTitleColor(tempProductoNombre.isEmpty ? .systemBlue : .label, for: .normal)
        prodBtn.frame = CGRect(x: 78, y: 4, width: wid - 86, height: 28)
        prodBtn.addAction(UIAction(handler: { [weak self, weak alert] _ in
            guard let self = self, let alert = alert else { return }
            alert.dismiss(animated: true) { [weak self] in self?.showProductPicker() }
        }), for: .touchUpInside)
        alert.view.addSubview(prodBtn)

        let cantLabel = UILabel(); cantLabel.text = "Cantidad:"; cantLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        cantLabel.frame = CGRect(x: 8, y: 40, width: 65, height: 20); alert.view.addSubview(cantLabel)

        let cantTF = UITextField(); cantTF.text = tempCantidad; cantTF.keyboardType = .numberPad
        cantTF.borderStyle = .roundedRect; cantTF.font = .systemFont(ofSize: 13)
        cantTF.frame = CGRect(x: 78, y: 36, width: wid - 86, height: 28); alert.view.addSubview(cantTF)

        let fechaLabel = UILabel(); fechaLabel.text = "Fecha:"; fechaLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        fechaLabel.frame = CGRect(x: 8, y: 72, width: 50, height: 20); alert.view.addSubview(fechaLabel)

        let fechaTF = UITextField(); fechaTF.text = tempFecha; fechaTF.borderStyle = .roundedRect; fechaTF.font = .systemFont(ofSize: 13)
        fechaTF.frame = CGRect(x: 62, y: 68, width: wid - 70, height: 28); alert.view.addSubview(fechaTF)

        let motivoLabel = UILabel(); motivoLabel.text = "Motivo:"; motivoLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        motivoLabel.frame = CGRect(x: 8, y: 104, width: 55, height: 20); alert.view.addSubview(motivoLabel)

        let motivoTF = UITextField(); motivoTF.text = tempMotivo; motivoTF.borderStyle = .roundedRect; motivoTF.font = .systemFont(ofSize: 13)
        motivoTF.frame = CGRect(x: 66, y: 100, width: wid - 74, height: 28); alert.view.addSubview(motivoTF)

        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            guard let pid = self.tempProductoId else { return }
            let cantidad = Int(cantTF.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard cantidad > 0 else { return }
            self.tempCantidad = "\(cantidad)"
            self.tempFecha = fechaTF.text?.trimmingCharacters(in: .whitespaces) ?? FirebaseService.todayString()
            self.tempMotivo = motivoTF.text?.trimmingCharacters(in: .whitespaces) ?? ""
            self.saveConsumo(productoId: pid, cantidad: cantidad, fecha: self.tempFecha, motivo: self.tempMotivo)
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        if editingConsumo != nil {
            alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.deleteConsumo(self.editingConsumo!)
            })
        }
        present(alert, animated: true)
    }

    private func showProductPicker() {
        let vc = ConsumoProductPickerVC(productos: productos) { [weak self] prod in
            guard let self = self else { return }
            self.tempProductoId = prod["id"] as? Int
            self.tempProductoNombre = prod["nombre"] as? String ?? ""
            self.showForm()
        }
        let nav = UINavigationController(rootViewController: vc); nav.modalPresentationStyle = .pageSheet; present(nav, animated: true)
    }

    // MARK: - Save / Delete
    private func saveConsumo(productoId: Int, cantidad: Int, fecha: String, motivo: String) {
        Task {
            do {
                let prods = try await fb.getList("productos")
                let prodNombre = prods.first(where: { ($0["id"] as? Int) == productoId })?["nombre"] as? String ?? ""
                let now = FirebaseService.nowString()

                if let old = editingConsumo {
                    let oldId = old["id"] as? Int ?? 0
                    let oldPid = old["producto_id"] as? Int ?? 0
                    let oldQty = old["cantidad"] as? Int ?? 0

                    if let oldProd = prods.first(where: { ($0["id"] as? Int) == oldPid }) {
                        var stock = (oldProd["stock_actual"] as? Int ?? 0) + oldQty
                        if oldPid == productoId {
                            stock = max(0, stock - cantidad)
                        }
                        try await fb.updateInList("productos", idValue: oldPid, updates: ["stock_actual": stock])
                    }

                    if oldPid != productoId {
                        if let newProd = prods.first(where: { ($0["id"] as? Int) == productoId }) {
                            let stock = max(0, (newProd["stock_actual"] as? Int ?? 0) - cantidad)
                            try await fb.updateInList("productos", idValue: productoId, updates: ["stock_actual": stock])
                        }
                    }

                    try await fb.updateInList("autoconsumos", idValue: oldId, updates: [
                        "producto_id": productoId, "producto_nombre": prodNombre,
                        "cantidad": cantidad, "fecha": fecha, "motivo": motivo, "updated_at": now
                    ])
                } else {
                    if let prod = prods.first(where: { ($0["id"] as? Int) == productoId }) {
                        let stock = max(0, (prod["stock_actual"] as? Int ?? 0) - cantidad)
                        try await fb.updateInList("productos", idValue: productoId, updates: ["stock_actual": stock])
                    }
                    let newId = FirebaseService.nextId(in: consumos)
                    try await fb.addToList("autoconsumos", item: [
                        "id": newId, "producto_id": productoId, "producto_nombre": prodNombre,
                        "cantidad": cantidad, "fecha": fecha, "motivo": motivo,
                        "created_at": now, "updated_at": now
                    ])
                }
                loadData()
            } catch { print("Error save: \(error)") }
        }
    }

    private func deleteConsumo(_ c: [String: Any]) {
        Task { do {
            if let pid = c["producto_id"] as? Int, let qty = c["cantidad"] as? Int {
                let prods = try await fb.getList("productos")
                if let prod = prods.first(where: { ($0["id"] as? Int) == pid }) {
                    let restored = (prod["stock_actual"] as? Int ?? 0) + qty
                    try await fb.updateInList("productos", idValue: pid, updates: ["stock_actual": restored])
                }
            }
            try await fb.removeFromList("autoconsumos", idValue: c["id"] as? Int ?? 0)
            loadData()
        } catch { print("Error delete: \(error)") } }
    }
}

// MARK: - Product Picker
class ConsumoProductPickerVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    private let tableView = UITableView(); private let searchBar = UISearchBar()
    private var allProds: [[String: Any]] = []; private var filtered: [[String: Any]] = []
    private let onDone: (([String: Any]) -> Void)

    init(productos: [[String: Any]], onDone: @escaping (([String: Any]) -> Void)) {
        self.allProds = productos; self.filtered = productos; self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad(); title = "Seleccionar Producto"; view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))

        searchBar.delegate = self; searchBar.placeholder = "Buscar producto..."; searchBar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(searchBar)
        tableView.dataSource = self; tableView.delegate = self; tableView.register(UITableViewCell.self, forCellReuseIdentifier: "pc")
        tableView.backgroundColor = .clear; tableView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(tableView)
        NSLayoutConstraint.activate([searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor), tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        filtered = text.isEmpty ? allProds : allProds.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pc", for: indexPath)
        let p = filtered[indexPath.row]
        cell.textLabel?.text = "\(p["nombre"] as? String ?? "") — Stock: \(p["stock_actual"] as? Int ?? 0)"
        cell.textLabel?.font = .systemFont(ofSize: 13); cell.backgroundColor = .white
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onDone(self.filtered[indexPath.row])
        }
    }

    @objc private func cancel() { dismiss(animated: true) }
}
