//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol TokenFeeProvider: FeeSelectorFeesProvider {
    func updateFees()
}

protocol TokenFeeProviderInput: AnyObject {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> { get }
    var destinationAddressPublisher: AnyPublisher<String, Never> { get }
}
