//
//  SwapSummaryStepsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapSummaryStepRoutable: AnyObject {
    func summaryStepRequestEditSourceToken()
    func summaryStepRequestEditReceiveToken()
    func summaryStepRequestEditFee()
    func summaryStepRequestEditProviders()
}
