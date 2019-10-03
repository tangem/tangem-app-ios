//
//  Localizations.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

class Localizations {
    public static var localizationsBundle: Bundle = defaultBundle
    
    static let dialogSecurityDelay = translate("dialog_security_delay")
    static let unknownCardState = translate("nfc_unknown_card_state")
    static let nfcAlertSignCompleted = translate("nfc_alert_sign_completed")
    static let nfcSessionTimeout = translate("nfc_session_timeout")
    static let nfcAlertDefault = translate("nfc_alert_default")
    
    private static var defaultBundle: Bundle = {
        let selfBundle = Bundle(for: Localizations.self)
        if let path = selfBundle.path(forResource: "TangemSdk", ofType: "bundle"), //for pods
            let bundle = Bundle(path: path) {
            return bundle
        } else {
            return selfBundle
        }
    }()
    
    
    static func secondsLeft(_ p1: String) -> String {
        return translate("nfc_seconds_left", p1)
    }
    
    private static func translate( _ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key,  bundle: localizationsBundle, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
