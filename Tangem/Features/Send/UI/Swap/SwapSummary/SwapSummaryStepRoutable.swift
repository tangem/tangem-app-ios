//
//  SwapSummaryStepsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapSummaryStepRoutable: AnyObject {
    func summaryStepRequestEditSourceToken(tokenItem: TokenItem)
    func summaryStepRequestEditReceiveToken(tokenItem: TokenItem)
    func summaryStepRequestEditFee()
    func summaryStepRequestEditProviders()
}
