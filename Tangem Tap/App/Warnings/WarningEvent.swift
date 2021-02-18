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
    
    var locationsToDisplay: Set<WarningsLocation> {
        switch self {
        case .numberOfSignedHashesIncorrect: return [.main]
        case .rateApp: return [.main]
        }
    }
    
    var canBeDismissed: Bool {
        switch self {
        case .numberOfSignedHashesIncorrect: return false
        case .rateApp: return true
        }
    }
    
    var buttons: [WarningButton] {
        switch self {
        case .numberOfSignedHashesIncorrect: return []
        case .rateApp: return [.reportProblem, .rateApp]
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
