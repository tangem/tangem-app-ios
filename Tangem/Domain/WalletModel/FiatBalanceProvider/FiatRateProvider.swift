//
//  FiatRateProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol FiatRateProvider: FiatTokenBalanceProviderInput {
    var rate: WalletModelRate { get }
    var ratePublisher: AnyPublisher<WalletModelRate, Never> { get }

    func updateRate()
}
