//
//  TryHeartRateWatch.swift
//  TryHeartRateWatch
//
//  Created by Steven Ongkowidjojo on 16/10/24.
//

import AppIntents

struct TryHeartRateWatch: AppIntent {
    static var title: LocalizedStringResource { "TryHeartRateWatch" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
