//
//  HealthKitManager.swift
//  TryHeartRate
//
//  Created by Steven Ongkowidjojo on 14/10/24.
//

import SwiftUI
import HealthKit
import UserNotifications

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    // Observer query for heart rate updates
    var heartRateObserverQuery: HKObserverQuery?
    
    @Published var latestHeartRate: Int = 0
    
    init() {
        authorizeHealthKit()
        setupObserverQuery()
    }
    
    func authorizeHealthKit() {
        let readData = Set([
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
        ])
        let shareData = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])
        healthStore.requestAuthorization(toShare: shareData, read: readData) { (check, error) in
            if check {
                print("Permission Granted")
                self.getUserAge(completion: { _ in})
                self.latestHeartRate(completion: { _ in})
            }
        }
    }
    
    func requestAuthorization(){
        let options:UNAuthorizationOptions = [.alert,.sound,.badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { sucess, error in
            if let error = error{
                print("Error: - \(error.localizedDescription)")
            }else{
                print("Success")
            }
        }
    }
    
    func getUserAge(completion: @escaping (Int?) -> Void) {
        guard HKObjectType.characteristicType(forIdentifier: .dateOfBirth) != nil else {
            completion(nil)
            return
        }
        do {
            let dob = try healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            let currentDate = Date()
            let userAge = calendar.dateComponents([.year], from: dob.date!, to: currentDate)
            completion(userAge.year)
            print(userAge)
        } catch {
            print("Error getting user's age: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func latestHeartRate(completion: @escaping (Int) -> Void) {
        guard let quantitySampleType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        _ = Date() // Get readings up to the current date
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false) // Get most recent sample first
        
        let query = HKSampleQuery(sampleType: quantitySampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (query, results, error) in
            guard error == nil, let samples = results else {
                return
            }
            if let data = samples.first as? HKQuantitySample {
                let unit = HKUnit(from: "count/min")
                let latestHeartRate = data.quantity.doubleValue(for: unit)
                completion(Int(latestHeartRate))
                print(latestHeartRate)
            }
        }
        healthStore.execute(query)
    }
    
    // Setup observer query to monitor heart rate updates
    private func setupObserverQuery() {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Configure the query
        let query = HKObserverQuery(sampleType: quantityType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else { return }
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }
            // Call latestHeartRate to update the value
            self.latestHeartRate { heartRate in
                // Update UI with the new heart rate value
                DispatchQueue.main.async {
                    // Notify subscribers about the updated heart rate
                    self.objectWillChange.send()
                }
            }
            
            // Call the completion handler to indicate that the query has been processed
            completionHandler()
        }
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate) { success, error in
            if success {
                print("Background delivery enabled successfully.")
            } else if let error = error {
                print("Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }

}
