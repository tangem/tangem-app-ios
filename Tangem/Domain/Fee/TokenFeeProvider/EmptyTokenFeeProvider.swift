//
//  EmptyTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct EmptyTokenFeeProvider: TokenFeeProvider {
    let feeTokenItem: TokenItem
    var balanceState: FormattedTokenBalanceType { .failure(.empty("")) }

    var state: TokenFeeProviderState { .unavailable(.notSupported) }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { .just(output: state) }

    var fees: [LoadableTokenFee] { [] }
    var feesPublisher: AnyPublisher<[LoadableTokenFee], Never> { .just(output: fees) }

    func updateSupportingState(input: TokenFeeProviderInputData) {
        assertionFailure("Should not be called")
    }

    func setup(input: TokenFeeProviderInputData) {
        assertionFailure("Should not be called")
    }

    func updateFees() async {
        assertionFailure("Should not be called")
    }
}
