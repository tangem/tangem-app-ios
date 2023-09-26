//
//  FakeRatesRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeRatesRepository: RatesRepository {
    var rates: Rates {
        currentRates.value
    }

    var ratesPublisher: AnyPublisher<Rates, Never> {
        currentRates.eraseToAnyPublisher()
    }

    private let currentRates = CurrentValueSubject<Rates, Never>([:])

    init(walletManagers: [FakeWalletManager]) {
        let walletModels = walletManagers.flatMap { $0.walletModels }
        var filter = Set<String>()
        let zipped: [(String, Decimal)] = walletModels.compactMap {
            let id = $0.tokenItem.currencyId ?? ""
            if filter.contains(id) {
                return nil
            }

            filter.insert(id)
            return (
                id,
                Decimal(floatLiteral: Double.random(in: 1 ... 50000))
            )
        }
        currentRates.send(Dictionary(uniqueKeysWithValues: zipped))
    }

    func update() -> AnyPublisher<Rates, Never> {
        ratesPublisher
    }

    func rate(for coinId: String) async throws -> Decimal {
        return 1
    }

    func loadRates(coinIds: [String]) -> AnyPublisher<Rates, Never> {
        ratesPublisher
    }
}
