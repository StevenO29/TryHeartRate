//
//  ContentView.swift
//  HeartRateMonitorWatch Watch App
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import SwiftUI
import HealthKit
import WatchConnectivity

struct ContentView: View {
    
    @State private var currentHeartRate: String = "--"
    
    @State private var timer: Timer?
    @State private var startTime: Date?
    
    @ObservedObject var connectivityManager = WatchConnectivityManager.shared
    
    private var healthStore = HKHealthStore()
    @State private var heartRateQuery: HKQuery?
    
    var body: some View {
        VStack {
            Text(formatTime(connectivityManager.elapsedTime))
            
            Text("Heart Rate: \(currentHeartRate) bpm")
                .padding(.bottom, 20)
            
            Button(connectivityManager.isSessionRunning ? "End Session" : "Start Session") {
                if connectivityManager.isSessionRunning {
                    endSession()
                } else {
                    startSession()
                }
            }
        }
        .onAppear {
            requestAuthorization()
            if connectivityManager.isSessionRunning {
                startTimer(from: Date().addingTimeInterval(-connectivityManager.elapsedTime))
            }
        }
        .padding()
    }
    
    private func startSession() {
        connectivityManager.isSessionRunning = true
        currentHeartRate = "--"
        startTimer(from: Date())
        startHeartRateMonitoring()
        connectivityManager.sendMessage(["action": "start", "elapsedTime": connectivityManager.elapsedTime]) // Kirim pesan start ke iPhone
    }
    
    private func endSession() {
        connectivityManager.isSessionRunning = false
        stopTimer()
        stopHeartRateMonitoring()
        connectivityManager.sendMessage(["action": "end"]) // Kirim pesan end ke iPhone
    }
    
    // Timer functions
    private func startTimer(from startDate: Date) {
        startTime = startDate
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = self.startTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                self.connectivityManager.elapsedTime = elapsedTime
                // Sinkronkan dengan iPhone
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
    
    // Heart rate monitoring functions
    private func startHeartRateMonitoring() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, _, _, _ in
            self.handleHeartRateSamples(samples)
        }
        
        query.updateHandler = { query, samples, _, _, _ in
            self.handleHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    private func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        currentHeartRate = "--"
    }
    
    private func handleHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        if let sample = heartRateSamples.first {
            let heartRateUnit = HKUnit(from: "count/min")
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            DispatchQueue.main.async {
                self.currentHeartRate = String(format: "%.0f", heartRate)
            }
        }
    }
    
    private func requestAuthorization() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                print("HealthKit authorization failed.")
            }
        }
    }
}

#Preview {
    ContentView()
}
