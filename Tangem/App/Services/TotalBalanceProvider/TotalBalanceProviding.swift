//
//  TotalBalanceProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

protocol TotalBalanceProviding {
    func subscribeToTotalBalance() -> AnyPublisher<ValueState<TotalBalanceProvider.TotalBalance>, Never>
    func updateTotalBalance()
}
