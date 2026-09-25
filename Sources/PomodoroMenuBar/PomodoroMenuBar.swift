import AppKit

private var globalDelegate: AppDelegate?

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var toggleMenuItem: NSMenuItem?

    var timer: Timer?
    var timeRemaining = 25 * 60 // Sekunden
    var isRunning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "🍅 XX:XX"
            button.target = self
            //button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusItemClicked)
        }

        setupMenu()
    }


    var menu = NSMenu()

    func setupMenu() {
        
        // 1. Menüeinträge anlegen
        let toggleItem = NSMenuItem(title: "Start", action: #selector(toggleTimer), keyEquivalent: "s")
        toggleItem.target = self // Sagt dem Item: Die Funktion 'toggleTimer' liegt in diesem AppDelegate
        self.toggleMenuItem = toggleItem
        
        let resetItem = NSMenuItem(title: "Reset", action: #selector(resetTimer), keyEquivalent: "r")
        resetItem.target = self
        
        let quitItem = NSMenuItem(title: "Beenden", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        
        // 2. Items zum Menü hinzufügen
        menu.addItem(toggleItem)
        menu.addItem(resetItem)
        menu.addItem(NSMenuItem.separator()) // Optische Trennlinie
        menu.addItem(quitItem)

        // 3. Menü zuweisen
        // statusItem.menu = menu
    }

    @objc func statusItemClicked() {
        statusItem.popUpMenu(menu)
    }

    // Start / Pause Umschalt-Logik
    @objc func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            isRunning = false

            toggleMenuItem?.title = "Start"
        } else {
            isRunning = true

            toggleMenuItem?.title = "Pause"
            
            // Startet einen Timer, der jede Sekunde den Block ausführt
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                // Wechselt für UI-Updates explizit auf den MainActor
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                        self.updateTitle()
                    } else {
                        self.timer?.invalidate()
                        self.isRunning = false
                        if let button = self.statusItem.button {
                            button.title = "🔔 Pause!"
                        }
                    }
                }
            }
        }
    }

    // Reset-Logik
    @objc func resetTimer() {
        timer?.invalidate()
        isRunning = false
        timeRemaining = 25 * 60
        toggleMenuItem?.title = "Start"
        updateTitle()
    }

    // Formatierung der verbleibenden Zeit
    func updateTitle() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        if let button = statusItem.button {
            button.title = "🍅 \(timeString)"
        }
    }

    @objc
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }

}

MainActor.assumeIsolated {
    let app = NSApplication.shared

    app.setActivationPolicy(.accessory)

    let delegate = AppDelegate()
    globalDelegate = delegate

    app.delegate = delegate
    app.run()
}
