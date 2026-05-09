import AppKit

@main
@MainActor
enum StickiesMain {
    private static let appDelegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared

        app.delegate = appDelegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
