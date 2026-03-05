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
    func userDidDismissFeeSelection()
}

extension FeeSelectorOutput {
    func userDidDismissFeeSelection() {}
}

protocol FeeSelectorRoutable: AnyObject {
    func closeFeeSelector()
}

protocol FeeSelectorAnalytics {
    func logFeeStepOpened()
    func logFeeSelected(tokenFee: TokenFee)
    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    func logFeeSelected(_ feeOption: FeeOption)
    func logFeeSummaryOpened()
    func logFeeTokensOpened(availableTokenFees: [TokenFee])
    func logCustomFeeClicked()
}
