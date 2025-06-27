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
    var fees: LoadingResult<[SendFee], Error> { get }
    var feesPublisher: AnyPublisher<LoadingResult<[SendFee], Error>, Never> { get }

    func updateFees()
}

extension SendFeeProvider {
    var feesHasVariants: AnyPublisher<Bool, Never> {
        feesPublisher.map { fees in
            let feeValues = fees.value ?? []
            let multipleFeeOptions = feeValues.count > 1
            let hasError = feeValues.contains { $0.value.error != nil }

            return multipleFeeOptions && !hasError
        }
        .eraseToAnyPublisher()
    }
}
