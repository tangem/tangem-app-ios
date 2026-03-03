//
//  ApproveViewModelInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation

protocol ApproveViewModelInput {
    var approveFeeValue: LoadingResult<ApproveInputFee, any Error> { get }

    func updateApprovePolicy(policy: ApprovePolicy)
    func sendApproveTransaction() async throws
}

struct ApproveInputFee {
    let feeTokenItem: TokenItem
    let fee: BSDKFee
}
