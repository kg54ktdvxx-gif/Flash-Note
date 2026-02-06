import OSLog

public enum FNLog {
    public static let capture = Logger(subsystem: "com.flashnote", category: "capture")
    public static let buffer = Logger(subsystem: "com.flashnote", category: "buffer")
    public static let voice = Logger(subsystem: "com.flashnote", category: "voice")
    public static let resurfacing = Logger(subsystem: "com.flashnote", category: "resurfacing")
    public static let sync = Logger(subsystem: "com.flashnote", category: "sync")
    public static let search = Logger(subsystem: "com.flashnote", category: "search")
    public static let export = Logger(subsystem: "com.flashnote", category: "export")
    public static let spotlight = Logger(subsystem: "com.flashnote", category: "spotlight")
    public static let watch = Logger(subsystem: "com.flashnote", category: "watch")
    public static let widget = Logger(subsystem: "com.flashnote", category: "widget")
    public static let intent = Logger(subsystem: "com.flashnote", category: "intent")
    public static let share = Logger(subsystem: "com.flashnote", category: "share")
}
