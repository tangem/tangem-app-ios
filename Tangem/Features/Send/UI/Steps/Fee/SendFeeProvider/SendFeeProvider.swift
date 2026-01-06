//
//  SendFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol SendFeeProviderInput: AnyObject {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> { get }
    var destinationAddressPublisher: AnyPublisher<String, Never> { get }
}

protocol SendFeeProvider {
    var fees: [SendFee] { get }
    var feesPublisher: AnyPublisher<[SendFee], Never> { get }

    func updateFees()
}

extension SendFeeProvider {
    var feesHasVariants: AnyPublisher<Bool, Never> {
        feesPublisher
            .filter { !$0.wrapToLoadingResult().isLoading }
            .map { fees in
                fees.hasMultipleFeeOptions
            }
            .eraseToAnyPublisher()
    }
}
