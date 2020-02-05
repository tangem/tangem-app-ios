//
//  Localizations.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public final class Localization {
    public static var localizationsBundle: Bundle?
    
    static let dialogSecurityDelay = string("dialog_security_delay")
    static let unknownCardState = string("nfc_unknown_card_state")
    static let nfcAlertSignCompleted = string("nfc_alert_sign_completed")
    static let nfcSessionTimeout = string("nfc_session_timeout")
    static let nfcAlertDefault = string("nfc_alert_default")
    static let nfcAlertDefaultDone = string("nfc_alert_default_done")
    static let nfcStuckError = string("nfc_stuck_error")
    static let unknownStatus = string("unknownStatus")
   
    static func genericErrorCode(_ code: String) -> String {
        return string("generic_error_code", code)
    }
    
    private static var defaultBundle: Bundle = {
        let selfBundle = Bundle(for: Localization.self)
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
        let format = getFormat(for: key)
        return String(format: format, locale: Locale.current, args)
    }
    
    private static func getFormat(for key: String) -> String {
        if let overridedBundle = localizationsBundle {
            let format = NSLocalizedString(key,  bundle: overridedBundle, comment: "")
            if format != key {
                return format
            }
        }
        let format = NSLocalizedString(key,  bundle: defaultBundle, comment: "")
        return format
    }
}
