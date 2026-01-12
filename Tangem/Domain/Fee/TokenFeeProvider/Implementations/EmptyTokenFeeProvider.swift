//
//  EmptyTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct EmptyTokenFeeProvider {
    let feeTokenItem: TokenItem
}

// MARK: - TokenFeeProvider

extension EmptyTokenFeeProvider: TokenFeeProvider {
    var state: TokenFeeProviderState { .idle }
    var statePublisher: AnyPublisher<TokenFeeProviderState, Never> { .just(output: state) }

    var fees: [TokenFee] { [] }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { .just(output: fees) }
}
