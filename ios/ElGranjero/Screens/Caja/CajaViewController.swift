import UIKit

class CajaViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        title = "Caja"

        let label = UILabel()
        label.text = "💰 Gestión de Caja"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let sublabel = UILabel()
        sublabel.text = "Próximamente"
        sublabel.font = UIFont.systemFont(ofSize: 16)
        sublabel.textColor = .gray
        sublabel.textAlignment = .center
        sublabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sublabel)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            sublabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sublabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8)
        ])

        // Firebase service integration placeholder:
        // FirestoreManager.shared.fetchCierres { cierres in ... }
    }
}
