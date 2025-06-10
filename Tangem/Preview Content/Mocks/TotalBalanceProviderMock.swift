//
//  TotalBalanceProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

struct TotalBalanceProviderMock: TotalBalanceProviding {
    var totalBalance: TotalBalanceState {
        .empty
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        Empty().eraseToAnyPublisher()
    }
}
