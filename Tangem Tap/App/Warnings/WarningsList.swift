//
//  WarningsList.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct WarningsList {
    static let warningTitle = "common_warning".localized
    
    static let oldCard = TapWarning(title: warningTitle, message: "alert_old_card".localized, priority: .info, type: .permanent)
    static let oldDeviceOldCard = TapWarning(title: warningTitle, message: "alert_old_device_this_card".localized, priority: .info, type: .permanent)
    static let devCard = TapWarning(title: warningTitle, message: "alert_developer_card".localized, priority: .critical, type: .permanent)
    static let numberOfSignedHashesIncorrect = TapWarning(title: warningTitle, message: "alert_card_signed_transactions".localized, priority: .info, type: .temporary, event: .numberOfSignedHashesIncorrect)
}
