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

protocol SendFeeInput: AnyObject, FeeSelectorInteractorInput {
    var selectedFee: TokenFee { get }
    var selectedFeePublisher: AnyPublisher<TokenFee, Never> { get }

    var canChooseFeeOption: AnyPublisher<Bool, Never> { get }
}

extension SendFeeInput {
    var selectedFee: TokenFee? { .some(selectedFee) }
    var selectedFeePublisher: AnyPublisher<TokenFee?, Never> { selectedFeePublisher.eraseToOptional().eraseToAnyPublisher() }
}

extension SendFeeInput where Self: TokenFeeProvider {
    /// Convenient extension when the object support `SendFeeInput` and `TokenFeeProvider`. E.g. `StakingModel`
    var canChooseFeeOption: AnyPublisher<Bool, Never> { feesHasVariants }
}

typealias SendFeeOutput = FeeSelectorOutput
