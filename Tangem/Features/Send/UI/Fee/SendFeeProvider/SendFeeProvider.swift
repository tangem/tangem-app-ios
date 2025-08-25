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
    /// Default supported fee options from provider
    var feeOptions: [FeeOption] { get }

    var fees: LoadingResult<[SendFee], Error> { get }
    var feesPublisher: AnyPublisher<LoadingResult<[SendFee], Error>, Never> { get }

    func updateFees()
}

extension SendFeeProvider {
    var feesHasVariants: AnyPublisher<Bool, Never> {
        feesPublisher
            .filter { !$0.isLoading }
            .map { fees in
                let feeValues = fees.value ?? []
                let multipleFeeOptions = feeValues.count > 1
                let hasError = feeValues.contains { $0.value.error != nil }

                return multipleFeeOptions && !hasError
            }
            .eraseToAnyPublisher()
    }
}
