import UIKit

class UsuariosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private var usuarios: [[String: Any]] = []
    private let fb = FirebaseService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        title = "Usuarios"

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addUser))
        navigationItem.rightBarButtonItem = addButton

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadUsers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUsers()
    }

    private func loadUsers() {
        Task {
            do {
                usuarios = try await fb.getList("usuarios")
                tableView.reloadData()
            } catch {
                print("Error loading users: \(error)")
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usuarios.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let u = usuarios[indexPath.row]
        let username = u["username"] as? String ?? ""
        let nombre = u["nombre_completo"] as? String ?? ""
        let rol = u["rol"] as? String ?? ""
        let activo = u["activo"] as? Bool ?? true
        cell.textLabel?.text = "\(username) - \(nombre) (\(rol))"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.backgroundColor = activo ? .white : UIColor.lightGray.withAlphaComponent(0.3)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = usuarios[indexPath.row]
        showUserActions(user, index: indexPath.row)
    }

    private func showUserActions(_ user: [String: Any], index: Int) {
        let alert = UIAlertController(title: user["username"] as? String ?? "Usuario", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Editar", style: .default) { [weak self] _ in
            self?.showUserForm(user: user, index: index)
        })
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.deleteUser(user, index: index)
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func addUser() {
        showUserForm(user: nil, index: nil)
    }

    private func showUserForm(user: [String: Any]?, index: Int?) {
        let alert = UIAlertController(title: user == nil ? "Nuevo Usuario" : "Editar Usuario", message: nil, preferredStyle: .alert)

        alert.addTextField { tf in tf.placeholder = "Username"; tf.text = user?["username"] as? String; tf.autocapitalizationType = .none }
        alert.addTextField { tf in tf.placeholder = "Nombre completo"; tf.text = user?["nombre_completo"] as? String }
        alert.addTextField { tf in tf.placeholder = "Email"; tf.text = user?["email"] as? String; tf.autocapitalizationType = .none; tf.keyboardType = .emailAddress }
        alert.addTextField { tf in tf.placeholder = "Teléfono"; tf.text = user?["telefono"] as? String }
        alert.addTextField { tf in tf.placeholder = "Contraseña"; tf.isSecureTextEntry = true }
        alert.addTextField { tf in tf.placeholder = "Rol"; tf.text = user?["rol"] as? String }

        let saveAction = UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let fields = alert.textFields ?? []
            let username = fields[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !username.isEmpty else { return }

            var data: [String: Any] = [
                "username": username,
                "nombre_completo": fields[1].text ?? "",
                "email": fields[2].text ?? "",
                "telefono": fields[3].text ?? "",
                "password": fields[4].text ?? (user?["password"] as? String ?? ""),
                "rol": fields[5].text ?? "",
                "activo": true
            ]
            if let existingId = user?["id"] as? Int {
                data["id"] = existingId
            }

            Task {
                do {
                    if user == nil {
                        data["id"] = FirebaseService.nextId(in: self.usuarios)
                        try await self.fb.addToList("usuarios", item: data)
                    } else {
                        try await self.fb.updateInList("usuarios", idValue: data["id"]!, updates: data)
                    }
                    self.loadUsers()
                } catch {
                    print("Error saving user: \(error)")
                }
            }
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func deleteUser(_ user: [String: Any], index: Int) {
        guard let id = user["id"] as? Int else { return }
        let confirm = UIAlertController(title: "Eliminar", message: "¿Eliminar usuario \(user["username"] as? String ?? "")?", preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await self?.fb.removeFromList("usuarios", idValue: id)
                    self?.loadUsers()
                } catch {
                    print("Error deleting user: \(error)")
                }
            }
        })
        confirm.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(confirm, animated: true)
    }
}
