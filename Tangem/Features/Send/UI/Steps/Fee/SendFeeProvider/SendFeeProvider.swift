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
    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }
    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> { get }

    func updateFees()
}

extension SendFeeProvider {
    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        feesPublisher
            .filter { !$0.eraseToLoadingResult().isLoading }
            .map { $0.hasMultipleFeeOptions }
            .eraseToAnyPublisher()
    }
}
