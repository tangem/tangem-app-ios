//
//  WarningEvent.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum WarningEvent {
    case devCard
    case numberOfSignedHashesIncorrect
    case oldDeviceOldCard
    
    var warning: TapWarning {
        let title = "common_warning".localized
        switch self {
        case .devCard:
            return TapWarning(title: title, message: "alert_developer_card".localized, priority: .critical, type: .permanent)
        case .numberOfSignedHashesIncorrect:
            return TapWarning(title: title, message: "alert_card_signed_transactions".localized, priority: .info, type: .temporary)
        case .oldDeviceOldCard:
            return TapWarning(title: title, message: "alert_old_device_this_card".localized, priority: .info, type: .temporary)
        }
    }
    
}

