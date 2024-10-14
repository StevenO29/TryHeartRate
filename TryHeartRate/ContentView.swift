//
//  ContentView.swift
//  TryHeartRate
//
//  Created by Steven Ongkowidjojo on 14/10/24.
//

import SwiftUI
import HealthKit
import Combine

struct ContentView: View {
    @State private var currentHeartRate: String = "0"
    @State private var minimumHeartRate: String = "0"
    @State private var maximumHeartRate: String = "0"
    @State private var averageHeartRate: String = "0"
    @State private var session: Bool = false
    @State private var timeSession: String = "00:00:00"
    
    @State private var timer: AnyCancellable? = nil
    @State private var startTime: Date? = nil
    
    private var healthStore = HKHealthStore()
    private var heartRateQuantity = HKUnit(from: "count/min")
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Current Heart Rate") {
                        TextField("Current", text: $currentHeartRate)
                            .disabled(true) // Disable editing for clarity
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
                    
                    Text(timeSession)
                        .font(.title)
                    
                    Button("Start Session") {
                        startSession()
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("End Session") {
                        endSession()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("HR Test Session")
        }
    }
    
    private func startSession() {
        resetStopwatch()
        startHeartRateSession()
        startStopwatch()
    }
    
    private func endSession() {
        endHeartRateSession()
        stopStopwatch()
    }
    
    private func resetStopwatch() {
        timer?.cancel()
        timer = nil
        startTime = nil
        timeSession = "00:00:00"
    }
    
    private func startStopwatch() {
        startTime = Date()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            updateStopwatch()
        }
    }
    
    private func stopStopwatch() {
        timer?.cancel()
        timer = nil
    }
    
    private func updateStopwatch() {
        guard let startTime = startTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        timeSession = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func startHeartRateSession() {
        requestAuthorization()
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            self.process(samples)
        }
        
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            self.process(samples)
        }
        
        healthStore.execute(query)
        session = true
    }
    
    private func endHeartRateSession() {
        session = false
    }
    
    private func process(_ samples: [HKQuantitySample]) {
        guard session else { return }
        
        let heartRates = samples.map { $0.quantity.doubleValue(for: heartRateQuantity) }
        
        DispatchQueue.main.async {
            if let currentHR = heartRates.last {
                self.currentHeartRate = String(Int(currentHR))
                self.minimumHeartRate = String(Int(heartRates.min() ?? 0))
                self.maximumHeartRate = String(Int(heartRates.max() ?? 0))
                self.averageHeartRate = String(Int(heartRates.reduce(0, +) / Double(heartRates.count)))
            }
        }
    }
    
    private func requestAuthorization() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set = [heartRateType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed")
            }
        }
    }
}

#Preview {
    ContentView()
}
