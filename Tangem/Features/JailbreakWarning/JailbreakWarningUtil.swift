//
//  JailbreakWarningUtil.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

struct JailbreakWarningUtil {
    private let rtcUtil = RTCUtil()

    func shouldShowWarning() -> Bool {
        if AppSettings.shared.jailbreakWarningWasShown {
            return false
        }

        return rtcUtil.checkStatus().hasIssues
    }

    func setWarningShown() {
        AppSettings.shared.jailbreakWarningWasShown = true
    }
}
