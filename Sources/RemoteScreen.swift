import SwiftUI
import WebKit

/// Holds the phone remote page and presses its buttons.
@MainActor
final class RemoteModel: NSObject, ObservableObject, WKNavigationDelegate {
    let web = WKWebView()
    let buttons = VolumeButtons()
    /// True when the last press did nothing: not connected, another phone in control, or the end of the deck.
    @Published var refused = false
    @Published var failed = false
    /// True while the page says the laptop is obeying a different phone.
    @Published var lockedOut = false
    private var checking: Timer?
    private let url: URL

    init(url: URL) {
        self.url = url
        super.init()
        web.navigationDelegate = self
        buttons.onPress = { [weak self] direction in self?.press(direction) }
        buttons.start()
        reload()
        // The page only says "Another device is in control". Watch for that so the app can say how to fix it.
        checking = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.web.evaluateJavaScript("(document.querySelector('.remote-banner')?.textContent||'').includes('Another device')") { result, _ in
                    self?.lockedOut = (result as? Bool) == true
                }
            }
        }
        #if targetEnvironment(simulator)
        // The simulator has no volume buttons. `xcrun simctl spawn booted notifyutil -p quickclick.next` stands in for one.
        for (name, direction) in [("quickclick.next", 1), ("quickclick.previous", -1)] {
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { _, _, name, _, _ in
                guard let name = name?.rawValue as String? else { return }
                DispatchQueue.main.async { NotificationCenter.default.post(name: Notification.Name(name), object: nil) }
            }, name as CFString, nil, .deliverImmediately)
            NotificationCenter.default.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.press(direction) }
            }
        }
        #endif
    }

    func reload() { failed = false; web.load(URLRequest(url: url)) }

    /// Clicks the page's own Next or Previous button, so every rule on the page still applies. A short tap means it went through, a triple buzz means it did not.
    func press(_ direction: Int) {
        let button = direction > 0 ? "remote-next" : "remote-previous"
        let script = "(()=>{const b=document.querySelector('.\(button)');if(!b||b.disabled)return false;b.click();return true})()"
        web.evaluateJavaScript(script) { [weak self] result, _ in
            let went = (result as? Bool) == true
            if went { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            else { UINotificationFeedbackGenerator().notificationOccurred(.error) }
            self?.refused = !went
        }
    }

    /// The page may only stay on the talk's site.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        action.request.url?.host == remoteHost ? .allow : .cancel
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed = true }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed = true }
}

/// The page plus the hidden volume view, which only works while it is inside the window.
struct RemotePage: UIViewRepresentable {
    let model: RemoteModel

    func makeUIView(context: Context) -> UIView {
        let box = UIView()
        model.web.frame = box.bounds
        model.web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        box.addSubview(model.web)
        box.addSubview(model.buttons.volumeView)
        return box
    }

    func updateUIView(_ view: UIView, context: Context) {}
}

struct RemoteScreen: View {
    let unpair: () -> Void
    @StateObject private var model: RemoteModel
    @State private var pocket = false

    init(url: URL, unpair: @escaping () -> Void) {
        self.unpair = unpair
        _model = StateObject(wrappedValue: RemoteModel(url: url))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Unpair", action: unpair).foregroundStyle(Theme.warning)
                Spacer()
                Button("Reload") { model.reload() }
                Spacer()
                Button("Pocket mode") { pocket = true }.buttonStyle(MainButtonStyle())
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            if model.failed {
                Text("The page did not load. Check the connection, then press Reload.").font(.footnote).foregroundStyle(Theme.warning).padding(.horizontal, 20).padding(.bottom, 8)
            }
            if model.lockedOut {
                Text("Another phone paired first. On the laptop, press Phone, then New code. Then tap Unpair here and scan the new code.")
                    .font(.footnote).foregroundStyle(Theme.warning).padding(.horizontal, 20).padding(.bottom, 8)
            }
            RemotePage(model: model)
        }
        .tint(Theme.ink)
        .background(Theme.ground.ignoresSafeArea())
        .overlay { if pocket { pocketCover } }
        .statusBarHidden(pocket)
        .persistentSystemOverlays(pocket ? .hidden : .automatic)
        // The phone must not lock itself: a locked phone stops hearing the buttons.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false; UIDevice.current.isProximityMonitoringEnabled = false }
        // In a pocket the sensor by the earpiece is covered, which turns the screen off and ignores touches.
        .onChange(of: pocket) { _, on in UIDevice.current.isProximityMonitoringEnabled = on }
    }

    /// A black screen that ignores taps. On an iPhone's screen, black pixels are switched off.
    private var pocketCover: some View {
        Color.black.ignoresSafeArea()
            .overlay {
                VStack(spacing: 10) {
                    Mark().fill(Color(white: 0.3)).frame(width: 30, height: 26).padding(.bottom, 8)
                    Text("Pocket mode")
                    Text("Volume up: next\nVolume down: previous").multilineTextAlignment(.center)
                    Text("Hold anywhere for one second to exit")
                    if model.refused { Text("Last press did not go through").foregroundStyle(Color(red: 0.6, green: 0.2, blue: 0.2)) }
                }
                .font(.footnote).foregroundStyle(Color(white: 0.3))
            }
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 1) { pocket = false }
    }
}
