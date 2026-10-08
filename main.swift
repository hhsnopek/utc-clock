import AppKit

final class Clock: NSObject, NSApplicationDelegate {
	private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	private let menu = NSMenu()
	private let time = utc("HH:mm 'UTC'")
	private let stamp = utc("yyyy-MM-dd HH:mm:ss")
	private var tick: Timer?

	func applicationDidFinishLaunching(_ notification: Notification) {
		menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
		item.button?.target = self
		item.button?.action = #selector(click)
		item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
		NSWorkspace.shared.notificationCenter.addObserver(
			self, selector: #selector(update), name: NSWorkspace.didWakeNotification, object: nil)
		update()
	}

	// One timer per minute boundary rather than a repeating one, so the
	// display stays on the minute after sleep or a clock change.
	@objc private func update() {
		tick?.invalidate()
		let now = Date()
		item.button?.title = time.string(from: now)
		let next = Date(timeIntervalSince1970: (now.timeIntervalSince1970 / 60).rounded(.down) * 60 + 60)
		tick = Timer(fireAt: next, interval: 0, target: self, selector: #selector(update), userInfo: nil, repeats: false)
		RunLoop.main.add(tick!, forMode: .common)
	}

	@objc private func click() {
		guard let event = NSApp.currentEvent else { return }
		if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
			item.menu = menu
			item.button?.performClick(nil)
			item.menu = nil
			return
		}
		NSPasteboard.general.clearContents()
		NSPasteboard.general.setString(timestamptz(Date()), forType: .string)
		item.button?.title = "Copied"
		perform(#selector(update), with: nil, afterDelay: 1)
	}

	// timestamptz renders date the way Postgres prints a timestamptz in a UTC
	// session. DateFormatter stops at milliseconds, so the microseconds are
	// formatted by hand from the whole-second remainder.
	private func timestamptz(_ date: Date) -> String {
		let t = date.timeIntervalSince1970
		let secs = t.rounded(.down)
		let micros = Int((t - secs) * 1_000_000)
		return stamp.string(from: Date(timeIntervalSince1970: secs)) + String(format: ".%06d+00", micros)
	}
}

func utc(_ format: String) -> DateFormatter {
	let f = DateFormatter()
	f.locale = Locale(identifier: "en_US_POSIX")
	f.timeZone = TimeZone(identifier: "UTC")
	f.dateFormat = format
	return f
}

let clock = Clock()
NSApplication.shared.delegate = clock
NSApplication.shared.run()
