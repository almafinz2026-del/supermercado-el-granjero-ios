import UIKit

class POSViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private let searchBar = UISearchBar()
    private let productosTable = UITableView()
    private let cartView = UIView()
    private let cartTable = UITableView()
    private let totalLabel = UILabel()
    private let checkoutBtn = UIButton(type: .system)
    private let clearBtn = UIButton(type: .system)

    private var productos: [[String: Any]] = []
    private var filtered: [[String: Any]] = []
    private var cart: [(producto: [String: Any], cantidad: Int)] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        title = "Ventas Super"

        searchBar.delegate = self; searchBar.placeholder = "Buscar producto..."; searchBar.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(searchBar)

        productosTable.dataSource = self; productosTable.delegate = self; productosTable.register(UITableViewCell.self, forCellReuseIdentifier: "prodCell"); productosTable.backgroundColor = .clear; productosTable.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(productosTable)

        cartView.backgroundColor = .white; cartView.layer.cornerRadius = 16; cartView.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(cartView)
        let cartTitle = UILabel(); cartTitle.text = "Carrito"; cartTitle.font = UIFont.boldSystemFont(ofSize: 16); cartTitle.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(cartTitle)

        cartTable.dataSource = self; cartTable.delegate = self; cartTable.register(UITableViewCell.self, forCellReuseIdentifier: "cartCell"); cartTable.backgroundColor = .clear; cartTable.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(cartTable)

        totalLabel.font = UIFont.boldSystemFont(ofSize: 22); totalLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1); totalLabel.textAlignment = .center; totalLabel.text = "$0"; totalLabel.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(totalLabel)

        clearBtn.setTitle("Limpiar", for: .normal); clearBtn.setTitleColor(.systemRed, for: .normal); clearBtn.addTarget(self, action: #selector(clearCart), for: .touchUpInside)
        checkoutBtn.setTitle("Cobrar", for: .normal); checkoutBtn.backgroundColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1); checkoutBtn.setTitleColor(.white, for: .normal); checkoutBtn.layer.cornerRadius = 12; checkoutBtn.addTarget(self, action: #selector(checkout), for: .touchUpInside)

        let btnRow = UIStackView(arrangedSubviews: [clearBtn, checkoutBtn]); btnRow.axis = .horizontal; btnRow.spacing = 12; btnRow.distribution = .fillEqually; btnRow.translatesAutoresizingMaskIntoConstraints = false; cartView.addSubview(btnRow)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            productosTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor), productosTable.leadingAnchor.constraint(equalTo: view.leadingAnchor), productosTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cartView.topAnchor.constraint(equalTo: productosTable.bottomAnchor, constant: 8), cartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8), cartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8), cartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8), cartView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            cartTitle.topAnchor.constraint(equalTo: cartView.topAnchor, constant: 8), cartTitle.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 12),
            cartTable.topAnchor.constraint(equalTo: cartTitle.bottomAnchor, constant: 4), cartTable.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 4), cartTable.trailingAnchor.constraint(equalTo: cartView.trailingAnchor, constant: -4),
            totalLabel.topAnchor.constraint(equalTo: cartTable.bottomAnchor, constant: 4), totalLabel.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 12), totalLabel.trailingAnchor.constraint(equalTo: cartView.trailingAnchor, constant: -12),
            btnRow.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8), btnRow.leadingAnchor.constraint(equalTo: cartView.leadingAnchor, constant: 12), btnRow.trailingAnchor.constraint(equalTo: cartView.trailingAnchor, constant: -12), btnRow.bottomAnchor.constraint(equalTo: cartView.bottomAnchor, constant: -12), btnRow.heightAnchor.constraint(equalToConstant: 44)
        ])

        loadProductos()
    }

    private func loadProductos() { Task { do { productos = try await fb.getList("productos"); filtered = productos; productosTable.reloadData() } catch { print("Error: \(error)") } } }

    func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        if text.isEmpty { filtered = productos }
        else { filtered = productos.filter { ($0["nombre"] as? String ?? "").localizedCaseInsensitiveContains(text) || ($0["codigo"] as? String ?? "").localizedCaseInsensitiveContains(text) } }
        productosTable.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tableView == productosTable ? filtered.count : cart.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == productosTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "prodCell", for: indexPath)
            let p = filtered[indexPath.row]; let name = p["nombre"] as? String ?? ""; let price = FirebaseService.formatMoney(p["precio_venta"] as? Double ?? 0)
            cell.textLabel?.text = "\(name) - \(price)"; cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .white
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cartCell", for: indexPath)
            let item = cart[indexPath.row]; let name = item.producto["nombre"] as? String ?? ""
            let price = (item.producto["precio_venta"] as? Double ?? 0) * Double(item.cantidad)
            cell.textLabel?.text = "\(name) x\(item.cantidad) = \(FirebaseService.formatMoney(price))"
            cell.textLabel?.font = UIFont.systemFont(ofSize: 13); cell.backgroundColor = .clear
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == productosTable {
            let p = filtered[indexPath.row]
            let alert = UIAlertController(title: "Cantidad", message: "¿Cuántos \"\(p["nombre"] as? String ?? "")\"?", preferredStyle: .alert)
            alert.addTextField { tf in tf.placeholder = "Cantidad"; tf.keyboardType = .numberPad; tf.text = "1" }
            alert.addAction(UIAlertAction(title: "Agregar", style: .default) { [weak self] _ in
                guard let self = self else { return }
                let qty = Int(alert.textFields?.first?.text ?? "") ?? 1
                if let idx = self.cart.firstIndex(where: { ($0.producto["id"] as? Int) == (p["id"] as? Int) }) { self.cart[idx].cantidad += qty }
                else { self.cart.append((p, qty)) }
                self.updateTotal(); self.cartTable.reloadData()
            })
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            present(alert, animated: true)
        } else {
            cart.remove(at: indexPath.row); updateTotal(); cartTable.reloadData()
        }
    }

    private func updateTotal() {
        let total = cart.reduce(0.0) { $0 + ($1.producto["precio_venta"] as? Double ?? 0) * Double($1.cantidad) }
        totalLabel.text = FirebaseService.formatMoney(total)
    }

    @objc private func clearCart() { cart.removeAll(); updateTotal(); cartTable.reloadData() }

    @objc private func checkout() {
        guard !cart.isEmpty else { return }
        let total = cart.reduce(0.0) { $0 + ($1.producto["precio_venta"] as? Double ?? 0) * Double($1.cantidad) }
        let alert = UIAlertController(title: "Confirmar Venta", message: "Total: \(FirebaseService.formatMoney(total))", preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Efectivo recibido (opcional)"; tf.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cobrar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let recibido = Double(alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? total
            Task {
                do {
                    let cajas = try await self.fb.getList("cajas")
                    guard cajas.contains(where: { ($0["estado"] as? String) == "abierta" }) else {
                        await MainActor.run { self.showAlert("Error", "No hay caja abierta") }; return
                    }
                    let ventas = try await self.fb.getList("ventas")
                    let nextId = FirebaseService.nextId(in: ventas)
                    let items: [[String: Any]] = self.cart.map {
                        ["producto_id": $0.producto["id"] as? Int ?? 0, "nombre": $0.producto["nombre"] as? String ?? "", "cantidad": $0.cantidad, "precio_venta": $0.producto["precio_venta"] as? Double ?? 0, "precio_compra": $0.producto["precio_compra"] as? Double ?? 0]
                    }
                    let v: [String: Any] = ["id": nextId, "fecha": FirebaseService.nowString(), "total": total, "recibido": recibido, "cambio": max(0, recibido - total), "items": items, "cliente": "Mostrador", "estado": "completada", "tipo": "super"]
                    try await self.fb.addToList("ventas", item: v)
                    for item in self.cart {
                        if let pid = item.producto["id"] as? Int {
                            let stock = max(0, (item.producto["stock_actual"] as? Int ?? 0) - item.cantidad)
                            try await self.fb.updateInList("productos", idValue: pid, updates: ["stock_actual": stock])
                        }
                    }
                    if let abierta = cajas.first(where: { ($0["estado"] as? String) == "abierta" }), let cid = abierta["id"] as? Int {
                        try await self.fb.updateInList("cajas", idValue: cid, updates: ["ingresos": (abierta["ingresos"] as? Double ?? 0) + total])
                    }
                    await MainActor.run { self.clearCart() }
                } catch { print("Error: \(error)") }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert); a.addAction(UIAlertAction(title: "OK", style: .default)); present(a, animated: true)
    }
}
