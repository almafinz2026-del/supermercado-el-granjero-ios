import UIKit

class CajaViewController: UIViewController {

    private let fb = FirebaseService.shared
    private let stackView = UIStackView()
    private let estadoLabel = UILabel()
    private let balanceLabel = UILabel()
    private let ingresosLabel = UILabel()
    private let egresosLabel = UILabel()
    private let actionBtn = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        title = "Caja"

        stackView.axis = .vertical; stackView.spacing = 16; stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        let card = UIView(); card.backgroundColor = .white; card.layer.cornerRadius = 16; card.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(card)

        let innerStack = UIStackView(); innerStack.axis = .vertical; innerStack.spacing = 12; innerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerStack)
        NSLayoutConstraint.activate([innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20), innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20), innerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)])

        estadoLabel.font = UIFont.boldSystemFont(ofSize: 22); estadoLabel.textAlignment = .center; innerStack.addArrangedSubview(estadoLabel)
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 32); balanceLabel.textAlignment = .center; balanceLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1); innerStack.addArrangedSubview(balanceLabel)
        ingresosLabel.font = UIFont.systemFont(ofSize: 14); ingresosLabel.textColor = .gray; innerStack.addArrangedSubview(ingresosLabel)
        egresosLabel.font = UIFont.systemFont(ofSize: 14); egresosLabel.textColor = .gray; innerStack.addArrangedSubview(egresosLabel)

        actionBtn.backgroundColor = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1); actionBtn.setTitleColor(.white, for: .normal); actionBtn.layer.cornerRadius = 14; actionBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17); actionBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true; actionBtn.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        stackView.addArrangedSubview(actionBtn)

        refresh()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); refresh() }

    private func refresh() {
        Task {
            do {
                let cajas = try await fb.getList("cajas")
                if let abierta = cajas.first(where: { $0["estado"] as? String == "abierta" }) {
                    estadoLabel.text = "Caja Abierta"
                    let ingresos = abierta["ingresos"] as? Double ?? 0; let egresos = abierta["egresos"] as? Double ?? 0
                    balanceLabel.text = FirebaseService.formatMoney(ingresos - egresos)
                    ingresosLabel.text = "Ingresos: \(FirebaseService.formatMoney(ingresos))"
                    egresosLabel.text = "Egresos: \(FirebaseService.formatMoney(egresos))"
                    actionBtn.setTitle("Cerrar Caja", for: .normal)
                } else {
                    estadoLabel.text = "Caja Cerrada"; balanceLabel.text = "$0"; ingresosLabel.text = ""; egresosLabel.text = ""
                    actionBtn.setTitle("Abrir Caja", for: .normal)
                }
            } catch { print("Error: \(error)") }
        }
    }

    @objc private func actionTapped() {
        Task {
            do {
                let cajas = try await fb.getList("cajas")
                if let abierta = cajas.first(where: { $0["estado"] as? String == "abierta" }), let id = abierta["id"] as? Int {
                    try await fb.updateInList("cajas", idValue: id, updates: ["estado": "cerrada", "fecha_cierre": FirebaseService.nowString()])
                } else {
                    var caja: [String: Any] = ["id": FirebaseService.nextId(in: cajas), "estado": "abierta", "ingresos": 0, "egresos": 0, "fecha_apertura": FirebaseService.nowString(), "fecha_cierre": ""]
                    try await fb.addToList("cajas", item: caja)
                }
                refresh()
            } catch { print("Error: \(error)") }
        }
    }
}
