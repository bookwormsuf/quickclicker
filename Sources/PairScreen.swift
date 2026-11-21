import SwiftUI
import VisionKit

/// First screen: scan the QR code on the laptop, or paste the link.
struct PairScreen: View {
    var pair: (URL) -> Void
    @State private var scanning = false
    @State private var scanProblem = ""
    @State private var pasted = ""
    @State private var problem = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Mark().fill(Theme.ink).frame(width: 46, height: 40)
            Text("QuickClicker").font(.system(size: 40, weight: .bold)).padding(.top, 24)
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
            // A wrong code keeps the scanner open and says so there, so the next scan can follow straight away.
            ScanSheet(problem: scanProblem, found: { text in
                if let url = remoteURL(text) { scanning = false; pair(url) } else { scanProblem = "That is not a pairing code" }
            }, close: { scanning = false })
            .onAppear { scanProblem = "" }
        }
        #if targetEnvironment(simulator)
        // The simulator cannot be tapped from a script. Launching with `-scan YES` opens the sheet for a screenshot.
        .onAppear { if UserDefaults.standard.bool(forKey: "scan") { scanning = true } }
        #endif
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

/// The scanner sheet: the camera, a close button, a frame to aim at and instructions on a dark panel.
struct ScanSheet: View {
    var problem: String
    var found: (String) -> Void
    var close: () -> Void
    private var cameraWorks: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }

    var body: some View {
        ZStack {
            if cameraWorks { Scanner(found: found) } else { Theme.ground }
            // Only a guide for where to point. A code is read anywhere in view.
            Brackets().stroke(.white.opacity(cameraWorks ? 0.95 : 0.25), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 230, height: 230)
        }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Button(action: close) {
                Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 38, height: 38).background(.black.opacity(0.6), in: Circle())
            }
            .accessibilityLabel("Close").padding(16)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 6) {
                Text(title).font(.headline).foregroundStyle(problem.isEmpty || !cameraWorks ? .white : Theme.warning)
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity).padding(.vertical, 18).padding(.horizontal, 20)
            // Dark backing, so the words stay readable over a bright laptop screen.
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
    }

    private var title: String {
        if !cameraWorks { return "The camera is not available" }
        return problem.isEmpty ? "Scan the QR code on your laptop" : problem
    }

    private var detail: String {
        if !cameraWorks { return "Allow camera access in Settings, or close this and paste the link." }
        return problem.isEmpty ? "Press Phone, then New code, to show it" : "Press Phone, then New code, for a fresh one"
    }
}

/// Four rounded corner marks.
struct Brackets: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = rect.width * 0.24
        let radius = rect.width * 0.12
        var path = Path()
        for (x, y, dx, dy) in [(rect.minX, rect.minY, 1.0, 1.0), (rect.maxX, rect.minY, -1.0, 1.0), (rect.maxX, rect.maxY, -1.0, -1.0), (rect.minX, rect.maxY, 1.0, -1.0)] {
            path.move(to: CGPoint(x: x + arm * dx, y: y))
            path.addLine(to: CGPoint(x: x + radius * dx, y: y))
            path.addQuadCurve(to: CGPoint(x: x, y: y + radius * dy), control: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x, y: y + arm * dy))
        }
        return path
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
