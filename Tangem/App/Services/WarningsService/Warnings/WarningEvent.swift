//
//  WarningEvent.swift
//  Tangem
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
    case testnetCard
    case fundsRestoration
    
    var locationsToDisplay: Set<WarningsLocation> {
        switch self {
        case .numberOfSignedHashesIncorrect, .rateApp, .failedToValidateCard, .multiWalletSignedHashes, .fundsRestoration: return [.main]
        case .testnetCard: return [.main, .send]
        }
    }
    
    var canBeDismissed: Bool {
        switch self {
        case .numberOfSignedHashesIncorrect, .failedToValidateCard, .multiWalletSignedHashes, .testnetCard: return false
        case .rateApp, .fundsRestoration: return true
        }
    }
    
    var buttons: [WarningButton] {
        switch self {
        case .numberOfSignedHashesIncorrect: return [.okGotIt]
        case .multiWalletSignedHashes, .fundsRestoration: return [.learnMore]
        case .rateApp: return [.reportProblem, .rateApp]
        case .failedToValidateCard, .testnetCard: return []
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
