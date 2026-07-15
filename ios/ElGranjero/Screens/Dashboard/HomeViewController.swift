import UIKit

class HomeViewController: UIViewController {

    private let sidebarView = UIView()
    private let containerView = UIView()
    private let dimmingView = UIView()
    private var sidebarLeadingConstraint: NSLayoutConstraint!
    private var isSidebarOpen = false
    private let sidebarWidth: CGFloat = 260

    private var currentIndex = 0
    private let session = SessionManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        _filteredItems = Self.allModules.enumerated().compactMap { (i, item) in
            session.tienePermiso(Self.modulePerms[i]) ? item : nil
        }
        setupLayout()
        setupSidebar()
        showModule(at: 0)
    }

    // MARK: - Layout
    private func setupLayout() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.alpha = 0
        view.addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideSidebar))
        dimmingView.addGestureRecognizer(tap)

        sidebarView.backgroundColor = UIColor(red: 0.12, green: 0.28, blue: 0.22, alpha: 1)
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sidebarView)

        sidebarLeadingConstraint = sidebarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -sidebarWidth)
        NSLayoutConstraint.activate([
            sidebarView.topAnchor.constraint(equalTo: view.topAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidebarView.widthAnchor.constraint(equalToConstant: sidebarWidth),
            sidebarLeadingConstraint
        ])
    }

    // MARK: - Sidebar
    private func setupSidebar() {
        // Logo text
        let logoLabel = UILabel()
        logoLabel.text = "EG"
        logoLabel.font = UIFont.boldSystemFont(ofSize: 22)
        logoLabel.textColor = UIColor(red: 1, green: 0.84, blue: 0.2, alpha: 1)
        logoLabel.textAlignment = .center
        logoLabel.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        logoLabel.layer.cornerRadius = 20
        logoLabel.clipsToBounds = true
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(logoLabel)
        NSLayoutConstraint.activate([
            logoLabel.topAnchor.constraint(equalTo: sidebarView.safeAreaLayoutGuide.topAnchor, constant: 16),
            logoLabel.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor),
            logoLabel.widthAnchor.constraint(equalToConstant: 40),
            logoLabel.heightAnchor.constraint(equalToConstant: 40)
        ])

        // User info
        let nameLabel = UILabel()
        nameLabel.text = session.username ?? "El Granjero"
        nameLabel.font = UIFont.boldSystemFont(ofSize: 13)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 6),
            nameLabel.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: -8)
        ])

        let roleLabel = UILabel()
        let rolName = (session.currentUser?["rol"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isUserAdmin = session.username?.lowercased() == "admin" || session.username?.lowercased() == "nelson" || rolName == "jefe" || rolName == "admin" || rolName == "administrador"
        if isUserAdmin {
            roleLabel.text = "Acceso Total"
            roleLabel.textColor = UIColor(red: 1.0, green: 0.84, blue: 0.2, alpha: 1.0)
            roleLabel.font = UIFont.boldSystemFont(ofSize: 10)
        } else {
            roleLabel.text = "\(session.permCount) permisos"
            roleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            roleLabel.font = UIFont.systemFont(ofSize: 10)
        }
        roleLabel.textAlignment = .center
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(roleLabel)
        NSLayoutConstraint.activate([
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            roleLabel.centerXAnchor.constraint(equalTo: sidebarView.centerXAnchor)
        ])

        // Separator
        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        sep.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 10),
            sep.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor, constant: 16),
            sep.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: -16),
            sep.heightAnchor.constraint(equalToConstant: 1)
        ])

        // Scrollable menu
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: sidebarView.bottomAnchor, constant: -56)
        ])

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let items = filteredItems
        var itemIdx = 0
        for group in Self.moduleGroups {
            let filtered = group.indices.filter { i in
                guard let moduleIdx = Self.allModules.firstIndex(where: { $0.title == Self.allModules[i].title }) else { return false }
                return session.tienePermiso(Self.modulePerms[moduleIdx])
            }
            if filtered.isEmpty { continue }

            let sectionLabel = UILabel()
            sectionLabel.text = "   \(group.title.uppercased())"
            sectionLabel.font = UIFont.boldSystemFont(ofSize: 10)
            sectionLabel.textColor = UIColor.white.withAlphaComponent(0.5)
            sectionLabel.translatesAutoresizingMaskIntoConstraints = false
            sectionLabel.heightAnchor.constraint(equalToConstant: 26).isActive = true
            stackView.addArrangedSubview(sectionLabel)

            for i in filtered {
                let module = Self.allModules[i]
                let btn = UIButton(type: .system)
                btn.contentHorizontalAlignment = .left
                btn.setTitle("  \(module.title)", for: .normal)
                btn.setImage(UIImage(systemName: module.icon), for: .normal)
                btn.tintColor = currentIndex == itemIdx ? UIColor(red: 1, green: 0.84, blue: 0.2, alpha: 1) : UIColor.white.withAlphaComponent(0.8)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
                btn.tag = itemIdx
                btn.addTarget(self, action: #selector(moduleSelected(_:)), for: .touchUpInside)
                btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
                btn.backgroundColor = currentIndex == itemIdx ? UIColor.white.withAlphaComponent(0.1) : .clear
                btn.layer.cornerRadius = 6
                stackView.addArrangedSubview(btn)
                itemIdx += 1
            }
        }

        // Logout button pinned at bottom
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Cerrar Sesión", for: .normal)
        logoutButton.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        logoutButton.tintColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        logoutButton.contentHorizontalAlignment = .left
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.leadingAnchor.constraint(equalTo: sidebarView.leadingAnchor, constant: 12),
            logoutButton.trailingAnchor.constraint(equalTo: sidebarView.trailingAnchor, constant: -12),
            logoutButton.bottomAnchor.constraint(equalTo: sidebarView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            logoutButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }

    // MARK: - Module Navigation
    func showModule(at index: Int) {
        guard index >= 0, index < filteredItems.count else { return }
        currentIndex = index

        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let vc = filteredItems[index].vc
        addChild(vc)
        // Access view to force loadView/viewDidLoad on child
        let _ = vc.view
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)

        // Sync navigation bar items from the active child
        title = filteredItems[index].title
        navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        navigationItem.rightBarButtonItem = vc.navigationItem.rightBarButtonItem
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: self, action: #selector(toggleSidebar))

        // Refresh sidebar highlights
        for case let stackView as UIStackView in sidebarView.subviews.compactMap({ $0 as? UIScrollView }).first?.subviews.compactMap({ $0 as? UIStackView }) ?? [] {
            for case let btn as UIButton in stackView.arrangedSubviews {
                let idx = btn.tag
                let isActive = idx == index
                btn.tintColor = isActive ? UIColor(red: 1, green: 0.84, blue: 0.2, alpha: 1) : UIColor.white.withAlphaComponent(0.8)
                btn.backgroundColor = isActive ? UIColor.white.withAlphaComponent(0.1) : .clear
            }
        }
        
        hideSidebar()
    }

    @objc private func toggleSidebar() {
        if isSidebarOpen {
            hideSidebar()
        } else {
            showSidebar()
        }
    }

    @objc private func showSidebar() {
        isSidebarOpen = true
        sidebarLeadingConstraint.constant = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.dimmingView.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func hideSidebar() {
        isSidebarOpen = false
        sidebarLeadingConstraint.constant = -sidebarWidth
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.dimmingView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func moduleSelected(_ sender: UIButton) {
        showModule(at: sender.tag)
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Cerrar Sesión", message: "¿Estás seguro?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Salir", style: .destructive) { [weak self] _ in
            self?.session.clear()
            FirebaseService.shared.signOut()
            self?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Module Definitions
    struct ModuleItem {
        let title: String
        let icon: String
        let vc: UIViewController
    }

    static let modulePerms: [String] = [
        "dashboard", "caja", "ventas_super", "ventas_bar", "facturacion",
        "historial_ventas", "fiados", "productos", "compras", "compras_programadas",
        "categorias", "distribuciones", "clientes", "proveedores", "usuarios",
        "reportes", "cierres", "configuracion"
    ]

    static let allModules: [ModuleItem] = [
        ModuleItem(title: "Dashboard", icon: "square.grid.2x2", vc: DashboardViewController()),
        ModuleItem(title: "Caja", icon: "banknote", vc: CajaViewController()),
        ModuleItem(title: "Ventas Super", icon: "cart", vc: POSViewController()),
        ModuleItem(title: "Ventas Bar", icon: "wineglass", vc: BarViewController()),
        ModuleItem(title: "Facturación", icon: "doc.text", vc: FacturacionViewController()),
        ModuleItem(title: "Historial", icon: "clock.arrow.circlepath", vc: HistorialViewController()),
        ModuleItem(title: "Fiados", icon: "creditcard", vc: FiadosViewController()),
        ModuleItem(title: "Inventario", icon: "shippingbox", vc: InventarioViewController()),
        ModuleItem(title: "Compras", icon: "bag", vc: ComprasViewController()),
        ModuleItem(title: "Compras Prog.", icon: "calendar", vc: ComprasProgramadasViewController()),
        ModuleItem(title: "Categorías", icon: "folder", vc: CategoriasViewController()),
        ModuleItem(title: "Distribuciones", icon: "wallet.pass", vc: DistribucionesViewController()),
        ModuleItem(title: "Clientes", icon: "person.2", vc: ClientesViewController()),
        ModuleItem(title: "Proveedores", icon: "building.2", vc: ProveedoresViewController()),
        ModuleItem(title: "Usuarios", icon: "shield", vc: UsuariosViewController()),
        ModuleItem(title: "Reportes", icon: "chart.bar", vc: ReportesViewController()),
        ModuleItem(title: "Cierres", icon: "lock", vc: CierresViewController()),
        ModuleItem(title: "Configuración", icon: "gearshape", vc: ConfiguracionViewController()),
    ]

    private var _filteredItems: [ModuleItem]?
    var filteredItems: [ModuleItem] {
        if let items = _filteredItems { return items }
        let items = Self.allModules.enumerated().compactMap { (i, item) in
            session.tienePermiso(Self.modulePerms[i]) ? item : nil
        }
        _filteredItems = items
        return items
    }

    static let moduleGroups: [(title: String, indices: [Int])] = [
        ("Principal", [0, 1]),
        ("Ventas", [2, 3, 4, 5, 6]),
        ("Inventario y Compras", [7, 8, 9, 10, 11]),
        ("Gestión", [12, 13, 14]),
        ("Análisis", [15, 16, 17])
    ]
}
