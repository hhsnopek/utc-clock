import AppKit

final class Clock: NSObject, NSApplicationDelegate {
	private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
	private let menu = NSMenu()
	private let time = utc("HH:mm 'UTC'")
	private let stamp = utc("yyyy-MM-dd'T'HH:mm:ss")
	// Fixed-width digits keep the clock's width, and the icons beside it,
	// from shifting as the minutes change.
	private let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)
	private let icon = symbol("clock")
	private let copiedIcon = clipboardCircle(.systemGreen)
	private var tick: Timer?

	func applicationDidFinishLaunching(_ notification: Notification) {
		menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
		item.button?.font = font
		item.button?.image = icon
		item.button?.imagePosition = .imageLeading
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
		NSPasteboard.general.setString(rfc3339(Date()), forType: .string)
		confirm()
	}

	// Both icons are the same size, so the swap never moves the menu bar.
	private func confirm() {
		fade(to: copiedIcon)
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(restoreIcon), object: nil)
		perform(#selector(restoreIcon), with: nil, afterDelay: 1)
	}

	@objc private func restoreIcon() {
		fade(to: icon)
	}

	private func fade(to image: NSImage?) {
		guard let button = item.button else { return }
		let transition = CATransition()
		transition.type = .fade
		transition.duration = 0.2
		button.wantsLayer = true
		button.layer?.add(transition, forKey: nil)
		button.image = image
	}

	// DateFormatter stops at milliseconds, so the microseconds are formatted
	// by hand from the whole-second remainder.
	private func rfc3339(_ date: Date) -> String {
		let t = date.timeIntervalSince1970
		let secs = t.rounded(.down)
		let micros = Int((t - secs) * 1_000_000)
		return stamp.string(from: Date(timeIntervalSince1970: secs)) + String(format: ".%06dZ", micros)
	}
}

func utc(_ format: String) -> DateFormatter {
	let f = DateFormatter()
	f.locale = Locale(identifier: "en_US_POSIX")
	f.timeZone = TimeZone(identifier: "UTC")
	f.dateFormat = format
	return f
}

func symbol(_ name: String, scale: CGFloat = 1, weight: NSFont.Weight = .regular) -> NSImage? {
	let config = NSImage.SymbolConfiguration(pointSize: NSFont.menuBarFont(ofSize: 0).pointSize * scale, weight: weight)
	return NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config)
}

// SF Symbols has no clipboard in a circle, so this draws one from the circle
// the clock symbol is built on, with a clipboard inside at the weight of the
// clock's hands.
func clipboardCircle(_ color: NSColor) -> NSImage? {
	guard let ring = symbol("circle"), let glyph = symbol("clipboard", scale: 0.5, weight: .semibold) else { return nil }
	return NSImage(size: ring.size, flipped: false) { rect in
		ring.draw(in: rect)
		let g = glyph.size
		// A point above center, which reads as centered with the clip on top.
		glyph.draw(in: NSRect(x: (rect.width - g.width) / 2, y: (rect.height - g.height) / 2 + 1, width: g.width, height: g.height))
		color.set()
		rect.fill(using: .sourceAtop)
		return true
	}
}

let clock = Clock()
NSApplication.shared.delegate = clock
NSApplication.shared.run()
