import Foundation

class SessionManager {
    static let shared = SessionManager()
    
    private init() {}
    
    var currentUser: [String: Any]?
    var permisos: [String] = []
    var permCount: Int = 0
    
    // Permission constants - matching the 49 permission IDs from the Android app
    static let pantallas: [String] = [
        "dashboard", "caja", "ventas_super", "ventas_bar", "facturacion",
        "historial_ventas", "fiados", "productos", "compras", "compras_programadas",
        "categorias", "distribuciones", "clientes", "proveedores", "usuarios",
        "reportes", "cierres", "configuracion"
    ]
    
    static let acciones: [String] = [
        "crear_venta", "editar_venta", "eliminar_venta", "crear_producto",
        "editar_producto", "eliminar_producto", "crear_cliente", "editar_cliente",
        "eliminar_cliente", "crear_compra", "editar_compra", "eliminar_compra",
        "crear_proveedor", "editar_proveedor", "eliminar_proveedor",
        "abrir_caja", "cerrar_caja", "hacer_abono", "crear_fiado",
        "editar_fiado", "eliminar_fiado", "crear_usuario", "editar_usuario",
        "eliminar_usuario", "crear_rol", "editar_rol", "eliminar_rol",
        "crear_distribucion", "ver_reportes", "exportar_datos",
        "configurar_sistema"
    ]
    
    static let allPermisos: [String] = pantallas + acciones
    
    var username: String? {
        return currentUser?["username"] as? String
    }
    
    var nombreCompleto: String? {
        return currentUser?["nombre_completo"] as? String
    }
    
    var foto: String? {
        return currentUser?["foto"] as? String
    }
    
    func tienePermiso(_ permiso: String) -> Bool {
        if let userLower = username?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
            if userLower == "admin" || userLower == "nelson" {
                return true
            }
        }
        let roleLower = (currentUser?["rol"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if roleLower == "jefe" || roleLower == "admin" || roleLower == "administrador" {
            return true
        }
        return permisos.contains(permiso)
    }
    
    func puede(_ accion: String) -> Bool {
        return tienePermiso(accion)
    }
    
    func setUser(_ user: [String: Any], roles: [[String: Any]] = []) {
        currentUser = user
        let rolName = (user["rol"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isUserAdmin = (user["username"] as? String ?? "").lowercased() == "admin" || (user["username"] as? String ?? "").lowercased() == "nelson" || rolName == "jefe" || rolName == "admin" || rolName == "administrador"
        
        if isUserAdmin {
            permisos = Self.allPermisos
            permCount = Self.allPermisos.count
            return
        }
        
        var permisoIds = user["permiso_ids"] as? [Int] ?? []
        if permisoIds.isEmpty {
            if let role = roles.first(where: { ($0["nombre"] as? String ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == rolName }) {
                permisoIds = role["permiso_ids"] as? [Int] ?? []
            }
        }
        var resolved: [String] = []
        for id in permisoIds {
            if id >= 0 && id < Self.allPermisos.count {
                resolved.append(Self.allPermisos[id])
            }
        }
        permisos = resolved
        permCount = resolved.count
    }
    
    func clear() {
        currentUser = nil
        permisos = []
        permCount = 0
    }
    
    var isLoggedIn: Bool {
        return currentUser != nil
    }
}
