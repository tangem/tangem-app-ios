//
//  TangemPayMainHeaderBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemUI

struct TangemPayMainHeaderBalanceProvider {
    let tangemPayTokenBalanceProvider: TokenBalanceProvider
    let loadableTokenBalanceViewStateBuilder = LoadableBalanceViewStateBuilder()
}

// MARK: - MainHeaderBalanceProvider

extension TangemPayMainHeaderBalanceProvider: MainHeaderBalanceProvider {
    var balance: LoadableBalanceView.State {
        loadableTokenBalanceViewStateBuilder.build(
            type: tangemPayTokenBalanceProvider.formattedBalanceType
        )
    }

    var balancePublisher: AnyPublisher<LoadableBalanceView.State, Never> {
        tangemPayTokenBalanceProvider.formattedBalanceTypePublisher
            .map { loadableTokenBalanceViewStateBuilder.build(type: $0) }
            .eraseToAnyPublisher()
    }
}
