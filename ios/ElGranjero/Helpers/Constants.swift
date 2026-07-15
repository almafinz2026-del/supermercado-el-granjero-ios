import UIKit

struct AppColors {
    static let primary = UIColor(red: 0.1, green: 0.3, blue: 0.24, alpha: 1)
    static let primaryLight = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1)
    static let background = UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1)
    static let cardBackground = UIColor.white
    static let textDark = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    static let textMuted = UIColor.gray
    static let danger = UIColor.systemRed
    static let warning = UIColor.systemOrange
    static let success = UIColor(red: 0.18, green: 0.48, blue: 0.37, alpha: 1)
}

struct AppFonts {
    static func regular(_ size: CGFloat) -> UIFont { UIFont.systemFont(ofSize: size) }
    static func bold(_ size: CGFloat) -> UIFont { UIFont.boldSystemFont(ofSize: size) }
    static func medium(_ size: CGFloat) -> UIFont { UIFont.systemFont(ofSize: size, weight: .medium) }
}

struct DateFormatters {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
    
    static let displayDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "es_CO")
        return f
    }()
    
    static let displayDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy HH:mm"
        f.locale = Locale(identifier: "es_CO")
        return f
    }()
}
