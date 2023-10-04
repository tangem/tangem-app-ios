//
//  FakeTokenQuotesRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeTokenQuotesRepository: TokenQuotesRepository {
    var pricesPublisher: AnyPublisher<Quotes, Never> {
        currentPrices.eraseToAnyPublisher()
    }

    private let currentPrices = CurrentValueSubject<Quotes, Never>([:])
    private var bag = Set<AnyCancellable>()

    func quote(for item: TokenItem) -> TokenQuote? {
        guard let id = item.currencyId else {
            return nil
        }

        return currentPrices.value[id]
    }

    func quote(for coinId: String) -> TokenQuote? {
        return currentPrices.value[coinId]
    }

    func loadQuotes(coinIds: [String]) -> AnyPublisher<[TokenQuote], Never> {
        let filter = Set(coinIds)
        return currentPrices
            .map { newQuotes in
                newQuotes.filter {
                    filter.contains($0.key)
                }
                .map { $0.value }
            }
            .eraseToAnyPublisher()
    }

    func updateQuotes(coinIds: [String]) {
        let filter = Set(coinIds)
        return currentPrices
            .map { newQuotes in
                newQuotes.filter {
                    filter.contains($0.key)
                }
                .map { $0.value }
            }
            .sink()
            .store(in: &bag)
    }
}
