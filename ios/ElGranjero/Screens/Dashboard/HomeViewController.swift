import UIKit

class HomeViewController: UIViewController {
    
    private let containerView = UIView()
    private let drawerView = UIView()
    private let drawerOverlay = UIView()
    private var drawerLeadingConstraint: NSLayoutConstraint!
    private var isDrawerOpen = false
    
    private var currentIndex = 0
    private let session = SessionManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        setupNavigationBar()
        setupContainer()
        setupDrawer()
        showModule(at: 0)
    }
    
    private func setupNavigationBar() {
        title = currentModuleTitle
        navigationController?.navigationBar.tintColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: self, action: #selector(toggleDrawer))
        navigationItem.leftBarButtonItem = menuButton
        
        if let username = session.username {
            let permsLabel = UILabel()
            permsLabel.text = "\(session.permCount) permisos"
            permsLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            permsLabel.textColor = session.permCount > 0 ?
                UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1) : .systemRed
            permsLabel.backgroundColor = session.permCount > 0 ?
                UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 0.1) : UIColor.systemRed.withAlphaComponent(0.1)
            permsLabel.layer.cornerRadius = 10
            permsLabel.clipsToBounds = true
            permsLabel.textAlignment = .center
            permsLabel.sizeToFit()
            permsLabel.frame.size.width += 12
            permsLabel.frame.size.height = 20
            
            let usernameLabel = UILabel()
            usernameLabel.text = username
            usernameLabel.font = UIFont.systemFont(ofSize: 12)
            usernameLabel.textColor = .gray
            
            let stack = UIStackView(arrangedSubviews: [usernameLabel, permsLabel])
            stack.axis = .horizontal
            stack.spacing = 6
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: stack)
        }
    }
    
    private var currentModuleTitle: String {
        let items = filteredItems
        guard currentIndex < items.count else { return "Sin permisos" }
        return items[currentIndex].title
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
        ModuleItem(title: "Compras Prog.", icon: "calendar", vc: UIViewController()), // placeholder
        ModuleItem(title: "Categorías", icon: "folder", vc: CategoriasViewController()),
        ModuleItem(title: "Distribuciones", icon: "wallet.pass", vc: DistribucionesViewController()),
        ModuleItem(title: "Clientes", icon: "person.2", vc: ClientesViewController()),
        ModuleItem(title: "Proveedores", icon: "building.2", vc: ProveedoresViewController()),
        ModuleItem(title: "Usuarios", icon: "shield", vc: UsuariosViewController()),
        ModuleItem(title: "Reportes", icon: "chart.bar", vc: ReportesViewController()),
        ModuleItem(title: "Cierres", icon: "lock", vc: CierresViewController()),
        ModuleItem(title: "Configuración", icon: "gearshape", vc: ConfiguracionViewController()),
    ]
    
    var filteredItems: [ModuleItem] {
        Self.allModules.enumerated().compactMap { (i, item) in
            session.tienePermiso(Self.modulePerms[i]) ? item : nil
        }
    }
    
    static let moduleGroups: [(title: String, indices: [Int])] = [
        ("Principal", [0, 1]),
        ("Ventas", [2, 3, 4, 5, 6]),
        ("Inventario y Compras", [7, 8, 9, 10, 11]),
        ("Gestión", [12, 13, 14]),
        ("Análisis", [15, 16, 17])
    ]
    
    // MARK: - Container
    private func setupContainer() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func showModule(at index: Int) {
        guard index >= 0, index < filteredItems.count else { return }
        currentIndex = index
        title = filteredItems[index].title
        
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        let vc = filteredItems[index].vc
        addChild(vc)
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)
    }
    
    // MARK: - Drawer
    private func setupDrawer() {
        drawerOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        drawerOverlay.translatesAutoresizingMaskIntoConstraints = false
        drawerOverlay.alpha = 0
        view.addSubview(drawerOverlay)
        NSLayoutConstraint.activate([
            drawerOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            drawerOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawerOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            drawerOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleDrawer))
        drawerOverlay.addGestureRecognizer(tap)
        
        drawerView.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1)
        drawerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawerView)
        drawerLeadingConstraint = drawerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -300)
        NSLayoutConstraint.activate([
            drawerView.topAnchor.constraint(equalTo: view.topAnchor),
            drawerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            drawerView.widthAnchor.constraint(equalToConstant: 300),
            drawerLeadingConstraint
        ])
        
        // User header
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        drawerView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: drawerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: drawerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: drawerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 160)
        ])
        
        let iconView = UIImageView(image: UIImage(systemName: "store.fill"))
        iconView.tintColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        iconView.backgroundColor = .white
        iconView.layer.cornerRadius = 14
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            iconView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        let nameLabel = UILabel()
        nameLabel.text = session.username ?? "El Granjero"
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: iconView.centerYAnchor, constant: -2)
        ])
        
        let roleLabel = UILabel()
        roleLabel.text = "Sistema POS"
        roleLabel.font = UIFont.systemFont(ofSize: 11)
        roleLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(roleLabel)
        NSLayoutConstraint.activate([
            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2)
        ])
        
        // Menu items
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        drawerView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: drawerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: drawerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: drawerView.bottomAnchor, constant: -60)
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
            sectionLabel.text = group.title.uppercased()
            sectionLabel.font = UIFont.boldSystemFont(ofSize: 11)
            sectionLabel.textColor = UIColor.gray
            sectionLabel.translatesAutoresizingMaskIntoConstraints = false
            sectionLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
            stackView.addArrangedSubview(sectionLabel)
            
            for i in filtered {
                let module = Self.allModules[i]
                let btn = UIButton(type: .system)
                btn.contentHorizontalAlignment = .left
                btn.setTitle("  \(module.title)", for: .normal)
                btn.setImage(UIImage(systemName: module.icon), for: .normal)
                btn.tintColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
                btn.tag = itemIdx
                btn.addTarget(self, action: #selector(moduleSelected(_:)), for: .touchUpInside)
                btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
                
                if currentIndex == itemIdx {
                    btn.backgroundColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 0.08)
                }
                
                stackView.addArrangedSubview(btn)
                itemIdx += 1
            }
        }
        
        // Logout button (pinned at bottom)
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Cerrar Sesión", for: .normal)
        logoutButton.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        logoutButton.tintColor = .systemRed
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        logoutButton.contentHorizontalAlignment = .left
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        drawerView.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.leadingAnchor.constraint(equalTo: drawerView.leadingAnchor, constant: 16),
            logoutButton.trailingAnchor.constraint(equalTo: drawerView.trailingAnchor, constant: -16),
            logoutButton.bottomAnchor.constraint(equalTo: drawerView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }
    
    @objc private func toggleDrawer() {
        isDrawerOpen.toggle()
        drawerLeadingConstraint.constant = isDrawerOpen ? 0 : -300
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.drawerOverlay.alpha = self.isDrawerOpen ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func moduleSelected(_ sender: UIButton) {
        showModule(at: sender.tag)
        toggleDrawer()
    }
    
    @objc private func logoutTapped() {
        session.clear()
        FirebaseService.shared.signOut()
        dismiss(animated: true)
    }
}
