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
    static let warningTitle = "common_warning".localized

    static let oldCard = AppWarning(title: warningTitle, message: "alert_old_card".localized, priority: .info, type: .permanent)
    static let oldDeviceOldCard = AppWarning(title: warningTitle, message: "alert_old_device_this_card".localized, priority: .info, type: .permanent)
    static let devCard = AppWarning(title: warningTitle, message: "alert_developer_card".localized, priority: .critical, type: .permanent)
    static let numberOfSignedHashesIncorrect = AppWarning(title: warningTitle, message: "alert_card_signed_transactions".localized, priority: .info, type: .temporary, event: .numberOfSignedHashesIncorrect)
    static let rateApp = AppWarning(title: "warning_rate_app_title".localized, message: "warning_rate_app_message".localized, priority: .info, type: .temporary, event: .rateApp)
    static let failedToVerifyCard = AppWarning(title: "warning_failed_to_verify_card_title".localized, message: "warning_failed_to_verify_card_message".localized, priority: .critical, type: .permanent, event: .failedToValidateCard)
    static let multiWalletSignedHashes = AppWarning(title: "warning_important_security_info".localized, message: "warning_signed_tx_previously".localized, priority: .info, type: .temporary, location: [.main], event: .multiWalletSignedHashes)
    static let testnetCard = AppWarning(title: warningTitle, message: "warning_testnet_card_message".localized, priority: .critical, type: .permanent, location: [.main, .send], event: .testnetCard)
    static let demoCard = AppWarning(title: warningTitle, message: "alert_demo_message".localized, priority: .critical, type: .permanent, location: [.main, .send], event: .demoCard)
    static let legacyDerivation = AppWarning(title: warningTitle, message: "alert_manage_tokens_addresses_message".localized, priority: .critical, type: .permanent, location: [.manageTokens], event: .legacyDerivation)
    static func lowSignatures(count: Int) -> AppWarning {
        let message = String(format: "warning_low_signatures_format".localized, "\(count)")
        return AppWarning(title: warningTitle, message: message, priority: .critical, type: .permanent)
    }
}
