//
//  Localizations.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public class Localizations {
    
    public static var localizationsBundle: Bundle = defaultBundle
    private static var defaultBundle: Bundle = {
        let selfBundle = Bundle(for: Localizations.self)
        if let path = selfBundle.path(forResource: "TangemKit", ofType: "bundle"), //for pods
            let bundle = Bundle(path: path) {
            return bundle
        } else {
            return selfBundle
        }
    }()
    
    static let dialogSecurityDelay = translate("dialog_security_delay")
    static let unknownCardState = translate("nfc_unknown_card_state")
    static let nfcAlertSignCompleted = translate("nfc_alert_sign_completed")
    static let nfcSessionTimeout = translate("nfc_session_timeout")
    static let nfcAlertDefault = translate("nfc_alert_default")
    static let nfcStuckError = translate("nfc_stuck_error")
    static let slixFailedToParse = "Failed to read the Tag"
    static let xlmCreateAccountHint = translate("balance_validator_second_line_create_account_instruction")
    static let xlmAssetCreateAccountHint = translate("balance_validator_second_line_create_account_instruction_asset")
    static let accountNotFound = translate("balance_validator_first_line_account_not_found")
    static let loadMoreXrpToCreateAccount = translate("balance_validator_second_line_create_account_xrp")
    /// Cannot obtain data from blockchain
    static let loadedWalletErrorObtainingBlockchainData = translate("loaded_wallet_error_obtaining_blockchain_data")
    static func secondsLeft(_ p1: String) -> String {
        return translate("nfc_seconds_left", p1)
    }
}

extension Localizations {
    private static func translate( _ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key,  bundle: localizationsBundle, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
