//
//  TokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TokenFeeProvider {
    var feeTokenItem: TokenItem { get }

    var state: TokenFeeProviderState { get }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { get }

    var fees: [TokenFee] { get }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }

    func updateSupportingState(input: TokenFeeProviderInputData)
    func setup(input: TokenFeeProviderInputData)
    func updateFees() async
}
