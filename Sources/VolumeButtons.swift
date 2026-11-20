import AVFoundation
import MediaPlayer
import UIKit

/// Turns the volume buttons into two keys. iOS has no "button pressed" signal, so this watches the volume level:
/// a rise is +1, a fall is -1. After each press it puts the volume back to a resting level, so the buttons never run out at the top or bottom.
final class VolumeButtons: NSObject {
    var onPress: ((Int) -> Void)?
    /// Must sit inside the window (off screen is fine). It hides the system volume pop-up and holds the slider used to put the volume back.
    let volumeView = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
    private var watching: NSKeyValueObservation?
    private var rest: Float = 0.5
    private var slider: UISlider? { volumeView.subviews.compactMap { $0 as? UISlider }.first }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(start), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    /// Safe to call again. Runs each time the app comes to the front, because the system drops the audio session in the background.
    @objc func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient)
        try? session.setActive(true)
        // Rest near the volume the phone already had, but away from both ends.
        rest = min(max(session.outputVolume, 0.25), 0.75)
        settle()
        watching = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let level = change.newValue else { return }
            DispatchQueue.main.async { self?.changed(to: level) }
        }
    }

    private func changed(to level: Float) {
        let moved = level - rest
        guard abs(moved) > 0.001 else { return } // our own reset arriving back
        onPress?(moved > 0 ? 1 : -1)
        settle()
    }

    private func settle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.slider?.value = self.rest
        }
    }
}
