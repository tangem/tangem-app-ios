//
//  TangemPayMainHeaderBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa

struct TangemPayMainHeaderBalanceProvider {
    let tangemPayTokenBalanceProvider: TokenBalanceProvider
    let loadableTokenBalanceViewStateBuilder = LoadableTokenBalanceViewStateBuilder()
}

// MARK: - MainHeaderBalanceProvider

extension TangemPayMainHeaderBalanceProvider: MainHeaderBalanceProvider {
    var balance: LoadableTokenBalanceView.State {
        loadableTokenBalanceViewStateBuilder.build(
            type: tangemPayTokenBalanceProvider.formattedBalanceType
        )
    }

    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        tangemPayTokenBalanceProvider.formattedBalanceTypePublisher
            .map { loadableTokenBalanceViewStateBuilder.build(type: $0) }
            .eraseToAnyPublisher()
    }
}
