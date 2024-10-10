//
//  ApproveViewModelInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdkLocal

protocol ApproveViewModelInput {
    var approveFeeValue: LoadingValue<Fee> { get }
    var approveFeeValuePublisher: AnyPublisher<LoadingValue<Fee>, Never> { get }

    func updateApprovePolicy(policy: ApprovePolicy)
    func sendApproveTransaction() async throws
}
