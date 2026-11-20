import SwiftUI
import VisionKit

/// First screen: scan the QR code on the laptop, or paste the link.
struct PairScreen: View {
    var pair: (URL) -> Void
    @State private var scanning = false
    @State private var pasted = ""
    @State private var problem = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("FoF Clicker").font(.largeTitle.bold())
            Text("On the laptop, press Phone, then New code. Scan the code here.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button("Scan the code") { scanning = true }
                .buttonStyle(.borderedProminent).controlSize(.large)
            TextField("Or paste the link", text: $pasted)
                .textFieldStyle(.roundedBorder).textInputAutocapitalization(.never).autocorrectionDisabled()
            Button("Pair with pasted link") { use(pasted) }.disabled(pasted.isEmpty)
            Text(problem).foregroundStyle(.red).font(.footnote)
            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $scanning) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                Scanner { text in scanning = false; use(text) }.ignoresSafeArea()
            } else {
                Text("The camera is not available. Allow camera access in Settings, or paste the link.").padding()
            }
        }
    }

    private func use(_ text: String) {
        if let url = remoteURL(text) { pair(url) } else { problem = "That is not a remote link for the talk." }
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
