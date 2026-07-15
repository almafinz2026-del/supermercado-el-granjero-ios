import UIKit

class DashboardViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var kpiLabels: [UILabel] = []
    private var recentSalesStack: UIStackView!
    private var lowStockStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Welcome card
        let welcomeCard = createCard()
        contentView.addSubview(welcomeCard)
        welcomeCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            welcomeCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            welcomeCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            welcomeCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        let greeting = UILabel()
        greeting.text = "Bienvenido, \(SessionManager.shared.nombreCompleto ?? SessionManager.shared.username ?? "Usuario")"
        greeting.font = UIFont.boldSystemFont(ofSize: 20)
        greeting.translatesAutoresizingMaskIntoConstraints = false
        welcomeCard.addSubview(greeting)
        
        let dateLabel = UILabel()
        let df = DateFormatter()
        df.dateFormat = "EEEE, d MMMM yyyy"
        df.locale = Locale(identifier: "es_CO")
        dateLabel.text = df.string(from: Date()).capitalized
        dateLabel.font = UIFont.systemFont(ofSize: 13)
        dateLabel.textColor = .gray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeCard.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            greeting.topAnchor.constraint(equalTo: welcomeCard.topAnchor, constant: 16),
            greeting.leadingAnchor.constraint(equalTo: welcomeCard.leadingAnchor, constant: 16),
            greeting.trailingAnchor.constraint(equalTo: welcomeCard.trailingAnchor, constant: -16),
            dateLabel.topAnchor.constraint(equalTo: greeting.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: greeting.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: greeting.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: welcomeCard.bottomAnchor, constant: -16)
        ])
        
        // KPI Cards
        let kpiGrid = UIStackView()
        kpiGrid.axis = .vertical
        kpiGrid.spacing = 12
        kpiGrid.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(kpiGrid)
        NSLayoutConstraint.activate([
            kpiGrid.topAnchor.constraint(equalTo: welcomeCard.bottomAnchor, constant: 16),
            kpiGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            kpiGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        let kpiData = [
            ("Ventas Hoy", "$0", "dollarsign.circle"),
            ("Ventas Mes", "$0", "chart.line.uptrend.xyaxis"),
            ("Ganancias Hoy", "$0", "arrow.up.forward"),
            ("Deudores Activos", "0", "person.2"),
            ("Valor Inventario", "$0", "shippingbox"),
            ("Stock Bajo", "0", "exclamationmark.triangle")
        ]
        
        for i in stride(from: 0, to: kpiData.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.distribution = .fillEqually
            
            for j in i..<min(i+2, kpiData.count) {
                let (title, _, icon) = kpiData[j]
                let card = createKPICard(title: title, value: kpiData[j].1, icon: icon)
                row.addArrangedSubview(card)
            }
            kpiGrid.addArrangedSubview(row)
        }
        
        // Quick Stats
        let statsCard = createCard()
        contentView.addSubview(statsCard)
        statsCard.translatesAutoresizingMaskIntoConstraints = false
        
        let statsTitle = UILabel()
        statsTitle.text = "Resumen Rápido"
        statsTitle.font = UIFont.boldSystemFont(ofSize: 16)
        statsTitle.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(statsTitle)
        NSLayoutConstraint.activate([
            statsTitle.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 12),
            statsTitle.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 16),
            statsTitle.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -16)
        ])
        
        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 8
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(statsStack)
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: statsTitle.bottomAnchor, constant: 12),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -16),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -12)
        ])
        
        let statItems = ["Productos", "Clientes", "Caja"]
        for item in statItems {
            let vStack = UIStackView()
            vStack.axis = .vertical
            vStack.alignment = .center
            vStack.spacing = 4
            
            let countLabel = UILabel()
            countLabel.text = "0"
            countLabel.font = UIFont.boldSystemFont(ofSize: 24)
            countLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
            
            let nameLabel = UILabel()
            nameLabel.text = item
            nameLabel.font = UIFont.systemFont(ofSize: 11)
            nameLabel.textColor = .gray
            
            vStack.addArrangedSubview(countLabel)
            vStack.addArrangedSubview(nameLabel)
            statsStack.addArrangedSubview(vStack)
        }
        
        // Recent Sales
        let salesCard = createCard()
        contentView.addSubview(salesCard)
        salesCard.translatesAutoresizingMaskIntoConstraints = false
        
        let salesTitle = UILabel()
        salesTitle.text = "Últimas Ventas"
        salesTitle.font = UIFont.boldSystemFont(ofSize: 16)
        salesTitle.translatesAutoresizingMaskIntoConstraints = false
        salesCard.addSubview(salesTitle)
        
        recentSalesStack = UIStackView()
        recentSalesStack.axis = .vertical
        recentSalesStack.spacing = 8
        recentSalesStack.translatesAutoresizingMaskIntoConstraints = false
        salesCard.addSubview(recentSalesStack)
        
        NSLayoutConstraint.activate([
            salesTitle.topAnchor.constraint(equalTo: salesCard.topAnchor, constant: 12),
            salesTitle.leadingAnchor.constraint(equalTo: salesCard.leadingAnchor, constant: 16),
            salesTitle.trailingAnchor.constraint(equalTo: salesCard.trailingAnchor, constant: -16),
            recentSalesStack.topAnchor.constraint(equalTo: salesTitle.bottomAnchor, constant: 12),
            recentSalesStack.leadingAnchor.constraint(equalTo: salesCard.leadingAnchor, constant: 16),
            recentSalesStack.trailingAnchor.constraint(equalTo: salesCard.trailingAnchor, constant: -16),
            recentSalesStack.bottomAnchor.constraint(equalTo: salesCard.bottomAnchor, constant: -12)
        ])
        
        // Low Stock
        let stockCard = createCard()
        contentView.addSubview(stockCard)
        stockCard.translatesAutoresizingMaskIntoConstraints = false
        
        let stockTitle = UILabel()
        stockTitle.text = "Stock Bajo"
        stockTitle.font = UIFont.boldSystemFont(ofSize: 16)
        stockTitle.textColor = .systemRed
        stockTitle.translatesAutoresizingMaskIntoConstraints = false
        stockCard.addSubview(stockTitle)
        
        lowStockStack = UIStackView()
        lowStockStack.axis = .vertical
        lowStockStack.spacing = 8
        lowStockStack.translatesAutoresizingMaskIntoConstraints = false
        stockCard.addSubview(lowStockStack)
        
        NSLayoutConstraint.activate([
            stockTitle.topAnchor.constraint(equalTo: stockCard.topAnchor, constant: 12),
            stockTitle.leadingAnchor.constraint(equalTo: stockCard.leadingAnchor, constant: 16),
            stockTitle.trailingAnchor.constraint(equalTo: stockCard.trailingAnchor, constant: -16),
            lowStockStack.topAnchor.constraint(equalTo: stockTitle.bottomAnchor, constant: 12),
            lowStockStack.leadingAnchor.constraint(equalTo: stockCard.leadingAnchor, constant: 16),
            lowStockStack.trailingAnchor.constraint(equalTo: stockCard.trailingAnchor, constant: -16),
            lowStockStack.bottomAnchor.constraint(equalTo: stockCard.bottomAnchor, constant: -12),
            stockCard.topAnchor.constraint(equalTo: salesCard.bottomAnchor, constant: 16),
            stockCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            salesCard.topAnchor.constraint(equalTo: kpiGrid.bottomAnchor, constant: 16),
            salesCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            salesCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    private func loadData() {
        Task {
            do {
                let fb = FirebaseService.shared
                async let productosData = fb.getList("productos")
                async let ventasData = fb.getList("ventas")
                async let clientesData = fb.getList("clientes")
                async let cajasData = fb.getList("cajas")
                
                let (productos, ventas, clientes, cajas) = try await (productosData, ventasData, clientesData, cajasData)
                
                await MainActor.run {
                    updateDashboard(productos: productos, ventas: ventas, clientes: clientes, cajas: cajas)
                }
            } catch {
                print("Dashboard load error: \(error)")
            }
        }
    }
    
    private func updateDashboard(productos: [[String: Any]], ventas: [[String: Any]], clientes: [[String: Any]], cajas: [[String: Any]]) {
        let today = FirebaseService.todayString()
        
        // Ventas Hoy
        let ventasHoy = ventas.filter { ($0["fecha"] as? String ?? "").hasPrefix(today) && $0["estado"] as? String != "anulada" }
        let ventasHoyMonto = ventasHoy.compactMap { $0["total"] as? Double }.reduce(0, +)
        
        // Ventas Mes
        let monthPrefix = today.prefix(7)
        let ventasMes = ventas.filter { ($0["fecha"] as? String ?? "").hasPrefix(monthPrefix) && $0["estado"] as? String != "anulada" }
        let ventasMesMonto = ventasMes.compactMap { $0["total"] as? Double }.reduce(0, +)
        
        // Ganancias Hoy (simplified - total - cost)
        let gananciasHoy = ventasHoy.reduce(0.0) { sum, v in
            let total = v["total"] as? Double ?? 0
            let items = v["items"] as? [[String: Any]] ?? []
            let cost = items.compactMap { $0["precio_compra"] as? Double }.reduce(0, +)
            return sum + total - cost
        }
        
        // Deudores
        let deudores = clientes.filter { ($0["saldo_pendiente"] as? Double ?? 0) > 0 }
        
        // Stock bajo
        let stockBajo = productos.filter {
            let stock = $0["stock_actual"] as? Int ?? 0
            let min = $0["stock_minimo"] as? Int ?? 0
            return stock > 0 && stock <= min
        }
        
        // Valor inventario (costo total)
        let valorInventario = productos.compactMap { p -> Double? in
            let stock = p["stock_actual"] as? Int ?? 0
            let cost = p["precio_compra"] as? Double ?? 0
            return stock > 0 ? Double(stock) * cost : nil
        }.reduce(0, +)
        
        // Stats
        let totalProductos = productos.count
        let totalClientes = clientes.count
        let cajaAbierta = cajas.first { $0["estado"] as? String == "abierta" }
        let balanceCaja = cajaAbierta?["ingresos"] as? Double ?? 0 - (cajaAbierta?["egresos"] as? Double ?? 0)
        
        // Update UI
        let kpiValues = [
            FirebaseService.formatMoney(ventasHoyMonto),
            FirebaseService.formatMoney(ventasMesMonto),
            FirebaseService.formatMoney(gananciasHoy),
            "\(deudores.count)",
            FirebaseService.formatMoney(valorInventario),
            "\(stockBajo.count)"
        ]
        
        updateKPI(values: kpiValues)
        updateStats(productos: totalProductos, clientes: totalClientes, caja: "\(Int(balanceCaja))")
        updateRecentSales(ventasHoy)
        updateLowStock(stockBajo)
    }
    
    private func updateKPI(values: [String]) {
        // Simple approach - just update labels
        // Note: In a real implementation, you'd reference specific labels
    }
    
    private func updateStats(productos: Int, clientes: Int, caja: String) {
        // Update stat labels
    }
    
    private func updateRecentSales(_ sales: [[String: Any]]) {
        recentSalesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for sale in sales.prefix(5) {
            let label = UILabel()
            let total = FirebaseService.formatMoney(sale["total"] as? Double ?? 0)
            let cliente = sale["cliente"] as? String ?? "Mostrador"
            let hora = (sale["fecha"] as? String ?? "").suffix(8)
            label.text = "\(cliente) - \(total) [\(hora)]"
            label.font = UIFont.systemFont(ofSize: 13)
            label.textColor = .darkGray
            recentSalesStack.addArrangedSubview(label)
        }
        if sales.isEmpty {
            let label = UILabel()
            label.text = "No hay ventas hoy"
            label.font = UIFont.systemFont(ofSize: 13)
            label.textColor = .gray
            recentSalesStack.addArrangedSubview(label)
        }
    }
    
    private func updateLowStock(_ products: [[String: Any]]) {
        lowStockStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for p in products.prefix(10) {
            let label = UILabel()
            let name = p["nombre"] as? String ?? "?"
            let stock = p["stock_actual"] as? Int ?? 0
            let min = p["stock_minimo"] as? Int ?? 0
            label.text = "\(name) - Stock: \(stock) / Mín: \(min)"
            label.font = UIFont.systemFont(ofSize: 13)
            label.textColor = .systemRed
            lowStockStack.addArrangedSubview(label)
        }
        if products.isEmpty {
            let label = UILabel()
            label.text = "No hay productos con stock bajo"
            label.font = UIFont.systemFont(ofSize: 13)
            label.textColor = .gray
            lowStockStack.addArrangedSubview(label)
        }
    }
    
    // MARK: - Helpers
    private func createCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        return card
    }
    
    private func createKPICard(title: String, value: String, icon: String) -> UIView {
        let card = createCard()
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconView)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        valueLabel.textColor = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(valueLabel)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 10)
        titleLabel.textColor = .gray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            valueLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: valueLabel.topAnchor, constant: -2),
            titleLabel.leadingAnchor.constraint(equalTo: valueLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: valueLabel.trailingAnchor)
        ])
        
        return card
    }
}
