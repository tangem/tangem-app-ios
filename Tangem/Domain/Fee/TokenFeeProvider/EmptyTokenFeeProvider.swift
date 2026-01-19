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
    var balanceFeeTokenState: TokenBalanceType { .failure(.none) }
    var formattedFeeTokenBalance: FormattedTokenBalanceType { .failure(.empty("")) }
    var hasMultipleFeeOptions: Bool { false }

    var state: TokenFeeProviderState { .unavailable(.notSupported) }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { .just(output: state) }

    var selectedTokenFee: TokenFee {
        .init(option: .market, tokenItem: feeTokenItem, value: .failure(TokenFee.ErrorType.unsupportedByProvider))
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        .just(output: selectedTokenFee)
    }

    var fees: [TokenFee] { [] }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { .just(output: fees) }

    func updateSupportingState(input: TokenFeeProviderInputData) {
        assertionFailure("Should not be called")
    }

    func select(feeOption: FeeOption) {
        assertionFailure("Should not be called")
    }

    func setup(input: TokenFeeProviderInputData) {
        assertionFailure("Should not be called")
    }

    func updateFees() -> Task<Void, Never> {
        assertionFailure("Should not be called")
        return Task {}
    }
}
