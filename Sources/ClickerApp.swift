import SwiftUI

/// The only site this app will open. A scanned or pasted link must be a phone remote link on it.
let remoteHost = "friends-of-figma-talk.vercel.app"

/// Returns the link only if it is a phone remote link for the talk, so a stray QR code cannot open another page.
func remoteURL(_ text: String) -> URL? {
    guard let parts = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
          parts.scheme == "https", parts.host == remoteHost,
          let items = parts.queryItems,
          items.contains(where: { $0.name == "view" && $0.value == "remote" }),
          items.contains(where: { $0.name == "code" && !($0.value ?? "").isEmpty })
    else { return nil }
    return parts.url
}

@main
struct ClickerApp: App {
    /// The paired link is kept, so reopening the app goes straight back to the remote.
    @AppStorage("link") private var link = ""

    var body: some Scene {
        WindowGroup {
            Group {
            if let url = remoteURL(link) {
                RemoteScreen(url: url, unpair: { link = "" }).id(link)
            } else {
                PairScreen(pair: { link = $0.absoluteString })
            }
            }
            .preferredColorScheme(.dark)
        }
    }
}
