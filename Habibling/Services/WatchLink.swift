import Foundation
import WatchConnectivity

final class WatchLink: NSObject, ObservableObject {
    static let shared = WatchLink()

    var checkInHandler: ((UUID, Double) -> Void)?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = watchDelegate
        session.activate()
    }

    private let watchDelegate = PhoneWatchDelegate()

    func pushSnapshot(_ snapshot: HabiblingSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              let data = snapshot.encoded(),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        try? session.updateApplicationContext(["snapshot": payload])
    }
}

final class PhoneWatchDelegate: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated, let snapshot = HabiblingSnapshot.load() {
            Task { @MainActor in WatchLink.shared.pushSnapshot(snapshot) }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let idString = message["habitID"] as? String,
              let habitID = UUID(uuidString: idString) else { return }
        let value = (message["value"] as? NSNumber)?.doubleValue ?? 1
        DispatchQueue.main.async {
            WatchLink.shared.checkInHandler?(habitID, value)
        }
    }
}
