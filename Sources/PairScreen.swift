import SwiftUI
import VisionKit

/// First screen: scan the QR code on the laptop, or paste the link.
struct PairScreen: View {
    var pair: (URL) -> Void
    @State private var scanning = false
    @State private var pasted = ""
    @State private var problem = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Mark().fill(Theme.ink).frame(width: 46, height: 40)
            Text("QuickClick").font(.system(size: 40, weight: .bold)).padding(.top, 24)
            Text("Move your slides with the volume buttons.").foregroundStyle(Theme.dim).padding(.top, 6)
            VStack(alignment: .leading, spacing: 16) {
                step(1, "On the laptop, press Phone")
                step(2, "Press New code")
                step(3, "Scan the code here")
            }
            .padding(.top, 36)
            Spacer()
            Spacer()
            if !problem.isEmpty {
                Text(problem).font(.footnote).foregroundStyle(Theme.warning).padding(.bottom, 12)
            }
            Button("Scan the code") { scanning = true }.buttonStyle(MainButtonStyle(wide: true))
            // Rounded to match the button. A pasted link pairs by itself, so there is no second button.
            TextField("", text: $pasted, prompt: Text("Or paste the link").foregroundStyle(Theme.dim))
                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).submitLabel(.go)
                .padding(.vertical, 16).padding(.horizontal, 20)
                .background(Theme.faint, in: RoundedRectangle(cornerRadius: 16))
                .padding(.top, 12)
                .onSubmit { use(pasted) }
                .onChange(of: pasted) { _, text in
                    problem = ""
                    if let url = remoteURL(text) { pair(url) }
                }
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 28).padding(.bottom, 12)
        .background(Theme.ground.ignoresSafeArea())
        .sheet(isPresented: $scanning) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                Scanner { text in scanning = false; use(text) }.ignoresSafeArea()
            } else {
                Text("The camera is not available. Allow camera access in Settings, or paste the link.").padding()
            }
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 14) {
            Text("\(number)").font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28).background(Theme.faint, in: Circle())
            Text(text)
        }
    }

    private func use(_ text: String) {
        if let url = remoteURL(text) { pair(url) } else { problem = "That is not a pairing link for this deck." }
    }
}

/// The system QR scanner.
struct Scanner: UIViewControllerRepresentable {
    var found: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(found: found) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let found: (String) -> Void
        init(found: @escaping (String) -> Void) { self.found = found }

        func dataScanner(_ scanner: DataScannerViewController, didAdd added: [RecognizedItem], allItems: [RecognizedItem]) {
            for case .barcode(let code) in added {
                if let text = code.payloadStringValue { found(text); return }
            }
        }
    }
}
