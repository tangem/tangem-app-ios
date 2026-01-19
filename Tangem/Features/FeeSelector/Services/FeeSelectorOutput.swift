//
//  FeeSelectorOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol FeeSelectorOutput: AnyObject {
    func userDidFinishSelection(feeTokenItem: TokenItem, feeOption: FeeOption)
}

protocol FeeSelectorRoutable: AnyObject {
    func closeFeeSelector()
}

protocol FeeSelectorAnalytics {
    func logFeeStepOpened()
    func logSendFeeSelected(_ feeOption: FeeOption)
}
