//
//  WarningEvent+.swift
//  Tangem Tap
//
//  Created by Andrew Son on 28/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension WarningEvent {
    var warning: TapWarning {
        let title = "common_warning".localized
        switch self {
        case .numberOfSignedHashesIncorrect:
            return TapWarning(title: title, message: "alert_card_signed_transactions".localized, priority: .info, type: .temporary, event: .numberOfSignedHashesIncorrect)
        }
    }
}
