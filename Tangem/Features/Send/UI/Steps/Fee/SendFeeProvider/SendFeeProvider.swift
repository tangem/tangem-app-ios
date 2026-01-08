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

extension SendFeeProvider {
    var feesHasVariants: AnyPublisher<Bool, Never> {
        feesPublisher
            .filter { !$0.eraseToLoadingResult().isLoading }
            .map { $0.hasMultipleFeeOptions }
            .eraseToAnyPublisher()
    }
}
