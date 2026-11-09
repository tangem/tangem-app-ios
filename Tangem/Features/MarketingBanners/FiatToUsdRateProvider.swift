//
//  FiatToUsdRateProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class FiatToUsdRateProvider {
    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let referenceCoinId: String
    private let rateTasks = OSAllocatedUnfairLock(initialState: [String: Task<Decimal, Error>]())

    init(referenceCoinId: String = Constants.referenceCoinId) {
        self.referenceCoinId = referenceCoinId
    }

    func rate(for currencyCode: String) async throws -> Decimal {
        let currencyCode = currencyCode.uppercased()

        if currencyCode == Constants.usdCode {
            return 1
        }

        let task = rateTasks.withLock { tasks in
            if let task = tasks[currencyCode] {
                return task
            }

            let task = Task { try await self.loadRate(for: currencyCode) }
            tasks[currencyCode] = task
            return task
        }

        return try await task.value
    }
}

// MARK: - Private

private extension FiatToUsdRateProvider {
    func loadRate(for currencyCode: String) async throws -> Decimal {
        let request = QuotesDTO.Request(
            coinIds: [referenceCoinId],
            currencyId: currencyCode,
            fields: [.price, .priceUsd]
        )

        do {
            let quotes = try await apiService.loadQuotes(requestModel: request).async()

            guard let quote = quotes.first(where: { $0.id == referenceCoinId }),
                  quote.price > 0,
                  let priceUsd = quote.priceUsd else {
                throw FiatToUsdRateProviderError.rateUnavailable(currencyCode: currencyCode)
            }

            return priceUsd / quote.price
        } catch {
            rateTasks.withLock { _ = $0.removeValue(forKey: currencyCode) }
            throw error
        }
    }
}

extension FiatToUsdRateProvider {
    enum Constants {
        static let usdCode = "USD"
        static let referenceCoinId = "bitcoin"
    }
}

enum FiatToUsdRateProviderError: Error {
    case rateUnavailable(currencyCode: String)
}
