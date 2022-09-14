//
//  WarningEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum WarningEvent: Equatable {
    case numberOfSignedHashesIncorrect
    case multiWalletSignedHashes
    case rateApp
    case failedToValidateCard
    case testnetCard
    case demoCard
    case oldDeviceOldCard
    case oldCard
    case devCard
    case lowSignatures(count: Int)
    case legacyDerivation

    var locationsToDisplay: Set<WarningsLocation> {
        switch self {
        case .legacyDerivation:
            return [.manageTokens]
        case .testnetCard, .oldDeviceOldCard:
            return [.main, .send]
        default:
            return [.main]
        }
    }

    var canBeDismissed: Bool {
        switch self {
        case .rateApp:
            return true
        default:
            return false
        }
    }

    var buttons: [WarningButton] {
        switch self {
        case .numberOfSignedHashesIncorrect:
            return [.okGotIt]
        case .multiWalletSignedHashes:
            return [.learnMore]
        case .rateApp:
            return [.reportProblem, .rateApp]
        default:
            return []
        }
    }
}

enum WarningButton: String, Identifiable {
    case okGotIt
    case rateApp
    case reportProblem
    case dismiss
    case learnMore

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
