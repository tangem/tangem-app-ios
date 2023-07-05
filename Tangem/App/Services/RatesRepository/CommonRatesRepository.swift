//
//  CommonFiatRatesRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonRatesRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var _rates: CurrentValueSubject<Rates, Never> = .init([:])
    private var bag = Set<AnyCancellable>()

    private func loadRatesInternal(coinIds: [String], loadingPublisher: PassthroughSubject<Rates, Never>) {
        tangemApiService
            .loadRates(for: coinIds)
            .replaceError(with: [:])
            .sink(receiveValue: { [weak self] loadedRates in
                guard let self else { return }

                var current = _rates.value

                loadedRates.forEach {
                    current[$0.key] = $0.value
                }

                _rates.send(current)
                loadingPublisher.send(current)
            })
            .store(in: &bag)
    }
}

extension CommonRatesRepository: RatesRepository {
    var rates: Rates {
        _rates.value
    }

    var ratesPublisher: AnyPublisher<Rates, Never> {
        _rates.eraseToAnyPublisher()
    }

    func update() -> AnyPublisher<Rates, Never> {
        let allRates = [String](rates.keys)
        return loadRates(coinIds: allRates)
    }

    func update() async throws -> Rates {
        return try await update().async()
    }

    func loadRates(coinIds: [String]) -> AnyPublisher<Rates, Never> {
        let loadingPublisher = PassthroughSubject<Rates, Never>()

        defer {
            loadRatesInternal(coinIds: coinIds, loadingPublisher: loadingPublisher)
        }

        return loadingPublisher.eraseToAnyPublisher()
    }

    func loadRates(coinIds: [String]) async throws -> Rates {
        return try await loadRates(coinIds: coinIds).async()
    }

    func rate(for coinId: String) async throws -> Decimal {
        var rate = rates[coinId]

        if rate == nil {
            let loadedRates = try await loadRates(coinIds: [coinId])
            rate = loadedRates[coinId]
        }

        guard let rate else {
            throw CommonError.noData
        }

        return rate
    }
}
