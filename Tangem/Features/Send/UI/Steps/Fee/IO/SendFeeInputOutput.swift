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
    var selectedFee: SendFee { get }
    var selectedFeePublisher: AnyPublisher<SendFee, Never> { get }

    var canChooseFeeOption: AnyPublisher<Bool, Never> { get }
}

extension SendFeeInput where Self: SendFeeProvider {
    /// Convenient extension when the object support `SendFeeInput` and `SendFeeProvider`. E.g. `StakingModel`
    var canChooseFeeOption: AnyPublisher<Bool, Never> { feesHasVariants }
}

typealias SendFeeOutput = FeeSelectorOutput
