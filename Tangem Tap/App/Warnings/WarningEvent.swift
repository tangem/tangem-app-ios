//
//  WarningEvent.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum WarningEvent: String, Decodable {
    
    case numberOfSignedHashesIncorrect
    case rateApp
    case failedToValidateCard
    
    var locationsToDisplay: Set<WarningsLocation> {
        switch self {
        case .numberOfSignedHashesIncorrect, .rateApp, .failedToValidateCard: return [.main]
        }
    }
    
    var canBeDismissed: Bool {
        switch self {
        case .numberOfSignedHashesIncorrect, .failedToValidateCard: return false
        case .rateApp: return true
        }
    }
    
    var buttons: [WarningButton] {
        switch self {
        case .numberOfSignedHashesIncorrect: return [.okGotIt]
        case .rateApp: return [.reportProblem, .rateApp]
        case .failedToValidateCard: return []
        }
    }
    
}

enum WarningButton: String, Identifiable {
    case okGotIt, rateApp, reportProblem, dismiss
    
    var id: String { rawValue }
    
    var buttonTitle: String {
        switch self {
        case .okGotIt: return "warning_button_ok".localized
        case .rateApp: return "warning_button_really_cool".localized
        case .reportProblem: return "warning_button_can_be_better".localized
        case .dismiss: return ""
        }
    }
    
}
