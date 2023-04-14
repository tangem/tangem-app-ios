//
//  TotalBalanceProviderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

struct TotalBalanceProviderMock: TotalBalanceProviding {
    func totalBalancePublisher() -> AnyPublisher<LoadingValue<TotalBalanceProvider.TotalBalance>, Never> {
        Empty().eraseToAnyPublisher()
    }
}
