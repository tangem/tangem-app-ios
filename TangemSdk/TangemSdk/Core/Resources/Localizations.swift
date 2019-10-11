//
//  Localizations.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

final class Localizations {
    public static var localizationsBundle: Bundle = defaultBundle
    
    static let dialogSecurityDelay = string("dialog_security_delay")
    static let unknownCardState = string("nfc_unknown_card_state")
    static let nfcAlertSignCompleted = string("nfc_alert_sign_completed")
    static let nfcSessionTimeout = string("nfc_session_timeout")
    static let nfcAlertDefault = string("nfc_alert_default")
    
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
        return string("nfc_seconds_left", p1)
    }
    
    private static func string( _ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key,  bundle: localizationsBundle, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
