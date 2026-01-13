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

protocol SendFeeInput: AnyObject {
    var selectedFee: TokenFee { get }
    var selectedFeePublisher: AnyPublisher<TokenFee, Never> { get }

    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> { get }
}

extension SendFeeInput where Self: SendFeeProvider {
    /// Convenient extension when the object support `SendFeeInput` and `SendFeeProvider`. E.g. `StakingModel`
    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> { feesHasMultipleFeeOptions }
}

protocol SendFeeOutput: AnyObject {
    func feeDidChanged(fee: TokenFee)
}
