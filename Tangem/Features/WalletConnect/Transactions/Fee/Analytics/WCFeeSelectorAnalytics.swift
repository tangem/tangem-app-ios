//
//  WCFeeSelectorAnalytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class WCFeeSelectorAnalytics: FeeSelectorContentViewModelAnalytics {
    func logSendFeeSelected(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }
    }
}
