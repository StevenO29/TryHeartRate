//
//  WatchConnectivityManager.swift
//  TryHeartRate
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var isSessionRunning: Bool = false
    @Published var elapsedTime: TimeInterval = 0 // Waktu yang telah berjalan
    
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Send message to iPhone or Apple Watch
    func sendMessage(_ message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    // Handle receiving messages
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                if action == "start" {
                    self.isSessionRunning = true
                    if let elapsedTime = message["elapsedTime"] as? TimeInterval {
                        self.elapsedTime = elapsedTime
                    }
                } else if action == "end" {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    // Send current elapsed time to keep devices in sync
    func sendElapsedTimeUpdate(_ elapsedTime: TimeInterval) {
        sendMessage(["action": "sync", "elapsedTime": elapsedTime])
    }
    
    // WCSessionDelegate required methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
