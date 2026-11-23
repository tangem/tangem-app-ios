//
//  LendingFeeSelectorOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class LendingFeeSelectorOutput: FeeSelectorOutput {
    private let output: FeeSelectorOutput
    private let analyticsLogger: LendingAnalyticsLogger

    init(output: FeeSelectorOutput, analyticsLogger: LendingAnalyticsLogger) {
        self.output = output
        self.analyticsLogger = analyticsLogger
    }

    func userDidFinishSelection(feeProviderID: TokenFeeProviderID, feeOption: FeeOption) {
        analyticsLogger.logFeeSelected(feeOption)
        output.userDidFinishSelection(feeProviderID: feeProviderID, feeOption: feeOption)
    }
}
