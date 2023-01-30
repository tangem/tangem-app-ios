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
    case systemDeprecationTemporary
    case systemDeprecationPermanent(String)

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
        case .numberOfSignedHashesIncorrect, .systemDeprecationTemporary:
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
        case .okGotIt: return Localization.warningButtonOk
        case .rateApp: return Localization.warningButtonReallyCool
        case .reportProblem: return Localization.warningButtonCanBeBetter
        case .learnMore: return Localization.warningButtonLearnMore
        case .dismiss: return ""
        }
    }
}
