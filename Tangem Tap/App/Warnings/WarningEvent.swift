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
    case multiWalletSignedHashes
    case rateApp
    case failedToValidateCard
    
    var locationsToDisplay: Set<WarningsLocation> {
        switch self {
        case .numberOfSignedHashesIncorrect, .rateApp, .failedToValidateCard, .multiWalletSignedHashes: return [.main]
        }
    }
    
    var canBeDismissed: Bool {
        switch self {
        case .numberOfSignedHashesIncorrect, .failedToValidateCard, .multiWalletSignedHashes: return false
        case .rateApp: return true
        }
    }
    
    var buttons: [WarningButton] {
        switch self {
        case .numberOfSignedHashesIncorrect: return [.okGotIt]
        case .multiWalletSignedHashes: return [.learnMore]
        case .rateApp: return [.reportProblem, .rateApp]
        case .failedToValidateCard: return []
        }
    }
    
}

enum WarningButton: String, Identifiable {
    case okGotIt, rateApp, reportProblem, dismiss, learnMore
    
    var id: String { rawValue }
    
    var buttonTitle: String {
        switch self {
        case .okGotIt: return "warning_button_ok".localized
        case .rateApp: return "warning_button_really_cool".localized
        case .reportProblem: return "warning_button_can_be_better".localized
        case .learnMore: return "warning_button_learn_more".localized
        case .dismiss: return ""
        }
    }
    
}
