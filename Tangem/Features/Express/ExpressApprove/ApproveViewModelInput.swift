//
//  ApproveViewModelInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemFoundation

protocol ApproveViewModelInput {
    var approveFeeValue: LoadingResult<Fee, any Error> { get }
    var approveFeeValuePublisher: AnyPublisher<LoadingResult<Fee, any Error>, Never> { get }

    func updateApprovePolicy(policy: ApprovePolicy)
    func sendApproveTransaction() async throws
}
