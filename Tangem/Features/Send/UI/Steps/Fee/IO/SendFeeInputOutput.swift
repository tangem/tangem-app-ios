//
//  SendFeeInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Amount

protocol SendSummaryFeeInput: AnyObject {
    var summaryFee: LoadableTokenFee { get }
    var summaryFeePublisher: AnyPublisher<LoadableTokenFee, Never> { get }
    var summaryCanEditFeePublisher: AnyPublisher<Bool, Never> { get }
}

extension SendSummaryFeeInput where Self: SendFeeInput {
    var summaryFeePublisher: AnyPublisher<LoadableTokenFee, Never> {
        selectedFeePublisher.compactMap { $0 }.eraseToAnyPublisher()
    }
}

protocol SendFeeInput: AnyObject {
    var selectedFee: LoadableTokenFee? { get }
    var selectedFeePublisher: AnyPublisher<LoadableTokenFee?, Never> { get }

    var hasMultipleFeeOptions: AnyPublisher<Bool, Never> { get }
}

extension SendFeeInput where Self: SendSummaryFeeInput {
    /// Convenient extension when the object support `SendFeeInput` and `SendFeeProvider`. E.g. `StakingModel`
    var hasMultipleFeeOptions: AnyPublisher<Bool, Never> { summaryCanEditFeePublisher }
}

protocol SendFeeOutput: AnyObject {
    func feeDidChanged(fee: LoadableTokenFee)
}
