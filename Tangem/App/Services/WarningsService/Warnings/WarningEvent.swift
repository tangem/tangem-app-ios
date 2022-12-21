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
        case .okGotIt: return L10n.warningButtonOk
        case .rateApp: return L10n.warningButtonReallyCool
        case .reportProblem: return L10n.warningButtonCanBeBetter
        case .learnMore: return L10n.warningButtonLearnMore
        case .dismiss: return ""
        }
    }

}
