//
//  WarningEvent+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use NotificationView instead of AppWarning")
extension WarningEvent {
    var warning: AppWarning {
        AppWarning(
            title: title,
            message: description,
            priority: priority,
            type: type,
            location: Array(locationsToDisplay),
            event: self
        )
    }

    private var priority: WarningPriority {
        switch self {
        case .numberOfSignedHashesIncorrect, .multiWalletSignedHashes, .rateApp, .oldDeviceOldCard, .oldCard:
            return .info
        case .failedToValidateCard, .testnetCard, .demoCard, .devCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent:
            return .critical
        case .systemDeprecationTemporary:
            return .warning
        }
    }

    private var type: WarningType {
        switch self {
        case .numberOfSignedHashesIncorrect, .multiWalletSignedHashes, .rateApp, .systemDeprecationTemporary:
            return .temporary
        case .failedToValidateCard, .testnetCard, .demoCard, .oldDeviceOldCard, .oldCard, .devCard, .lowSignatures, .legacyDerivation, .systemDeprecationPermanent:
            return .permanent
        }
    }

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

    var buttons: [WarningView.WarningButton] {
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
