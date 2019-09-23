//
//  Localizations.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class Localizations {
    private static let bundle = Bundle(for: Localizations.self)
    
    static let dialogSecurityDelay = translate("dialog_security_delay")
    static let unknownCardState = translate("nfc_unknown_card_state")
    static let nfcAlertSignCompleted = translate("nfc_alert_sign_completed")
    static let nfcSessionTimeout = translate("nfc_session_timeout")
    static let nfcAlertDefault = translate("nfc_alert_default")
    static func secondsLeft(_ p1: String) -> String {
        return translate("nfc_seconds_left", p1)
    }
}

extension Localizations {
    private static func translate( _ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key,  bundle: bundle, comment: "")
        return String(format: format, locale: Locale.current, arguments: args)
    }
}
