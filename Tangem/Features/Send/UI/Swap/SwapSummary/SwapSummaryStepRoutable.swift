//
//  SwapSummaryStepsRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapSummaryStepRoutable: AnyObject {
    func summaryStepRequestEditSourceToken(receiveToken: WalletTokenItem?)
    func summaryStepRequestEditReceiveToken(sourceToken: WalletTokenItem?)
    func summaryStepRequestEditFee()
    func summaryStepRequestEditProviders()
}
