//
//  WarningEvent+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension WarningEvent {
    var warning: AppWarning {
        switch self {
        case .numberOfSignedHashesIncorrect:
            return WarningsList.numberOfSignedHashesIncorrect
        case .rateApp:
            return WarningsList.rateApp
        case .failedToValidateCard:
            return WarningsList.failedToVerifyCard
        case .multiWalletSignedHashes:
            return WarningsList.multiWalletSignedHashes
        case .testnetCard:
            return WarningsList.testnetCard
        case .lowSignatures(let count):
            return WarningsList.lowSignatures(count: count)
        case .demoCard:
            return WarningsList.demoCard
        case .devCard:
            return WarningsList.devCard
        case .oldCard:
            return WarningsList.oldCard
        case .oldDeviceOldCard:
            return WarningsList.oldDeviceOldCard
        case .legacyDerivation:
            return WarningsList.legacyDerivation
        }
    }
}

fileprivate struct WarningsList {
    static let warningTitle = L10n.commonWarning

    static let oldCard = AppWarning(title: warningTitle, message: L10n.alertOldCard, priority: .info, type: .permanent)
    static let oldDeviceOldCard = AppWarning(title: warningTitle, message: L10n.alertOldDeviceThisCard, priority: .info, type: .permanent)
    static let devCard = AppWarning(title: warningTitle, message: L10n.alertDeveloperCard, priority: .critical, type: .permanent)
    static let numberOfSignedHashesIncorrect = AppWarning(title: warningTitle, message: L10n.alertCardSignedTransactions, priority: .info, type: .temporary, event: .numberOfSignedHashesIncorrect)
    static let rateApp = AppWarning(title: L10n.warningRateAppTitle, message: L10n.warningRateAppMessage, priority: .info, type: .temporary, event: .rateApp)
    static let failedToVerifyCard = AppWarning(title: L10n.warningFailedToVerifyCardTitle, message: L10n.warningFailedToVerifyCardMessage, priority: .critical, type: .permanent, event: .failedToValidateCard)
    static let multiWalletSignedHashes = AppWarning(title: L10n.warningImportantSecurityInfo, message: L10n.warningSignedTxPreviously, priority: .info, type: .temporary, location: [.main], event: .multiWalletSignedHashes)
    static let testnetCard = AppWarning(title: warningTitle, message: L10n.warningTestnetCardMessage, priority: .critical, type: .permanent, location: [.main, .send], event: .testnetCard)
    static let demoCard = AppWarning(title: warningTitle, message: L10n.alertDemoMessage, priority: .critical, type: .permanent, location: [.main, .send], event: .demoCard)
    static let legacyDerivation = AppWarning(title: warningTitle, message: L10n.alertManageTokensAddressesMessage, priority: .critical, type: .permanent, location: [.manageTokens], event: .legacyDerivation)
    static func lowSignatures(count: Int) -> AppWarning {
        let message = L10n.warningLowSignaturesFormat("\(count)")
        return AppWarning(title: warningTitle, message: message, priority: .critical, type: .permanent)
    }
}
