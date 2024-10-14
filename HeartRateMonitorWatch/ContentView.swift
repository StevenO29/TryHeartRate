//
//  ContentView.swift
//  HeartRateMonitorWatch
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import SwiftUI
import HealthKit
import WatchConnectivity

struct ContentView: View {
    
    @State private var currentHeartRate: String = "0"
    @State private var minimumHeartRate: String = "0"
    @State private var maximumHeartRate: String = "0"
    @State private var averageHeartRate: String = "0"
    
    // Timer management
    @State private var timer: Timer?
    @State private var startTime: Date?
    
    // WatchConnectivityManager singleton instance
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Current Heart Rate") {
                        TextField("Current", text: $currentHeartRate)
                            .disabled(true)
                    }
                    
                    Section("Minimum Heart Rate") {
                        TextField("Minimum", text: $minimumHeartRate)
                            .disabled(true)
                    }
                    
                    Section("Maximum Heart Rate") {
                        TextField("Maximum", text: $maximumHeartRate)
                            .disabled(true)
                    }
                    
                    Section("Average Heart Rate") {
                        TextField("Average", text: $averageHeartRate)
                            .disabled(true)
                    }
                    
                    Text(formatTime(connectivityManager.elapsedTime))
                        .font(.title)
                    
                    Button(connectivityManager.isSessionRunning ? "End Session" : "Start Session") {
                        if connectivityManager.isSessionRunning {
                            endSession()
                        } else {
                            startSession()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(connectivityManager.isSessionRunning ? .red : .blue)
                }
            }
            .navigationTitle("HR Test Session")
            .onAppear {
                if connectivityManager.isSessionRunning {
                    // Continue timer if the session is already running
                    startTimer(from: Date().addingTimeInterval(-connectivityManager.elapsedTime))
                }
            }
        }
    }
    
    private func startSession() {
        connectivityManager.isSessionRunning = true
        startTimer(from: Date())
        connectivityManager.sendMessage(["action": "start", "elapsedTime": connectivityManager.elapsedTime])
    }
    
    private func endSession() {
        connectivityManager.isSessionRunning = false
        stopTimer()
        connectivityManager.sendMessage(["action": "end"])
    }
    
    private func startTimer(from startDate: Date) {
        startTime = startDate
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = self.startTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                self.connectivityManager.elapsedTime = elapsedTime
                // Sync with the other device
                self.connectivityManager.sendElapsedTimeUpdate(elapsedTime)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        connectivityManager.elapsedTime = 0
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    ContentView()
}
