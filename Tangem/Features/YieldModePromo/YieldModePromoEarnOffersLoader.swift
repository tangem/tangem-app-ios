//
//  YieldModePromoEarnOffersLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol YieldModePromoEarnOffersLoader {
    func loadYieldOffers() async throws -> EarnDTO.List.Response
}

struct CommonYieldModePromoEarnOffersLoader: YieldModePromoEarnOffersLoader {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    func loadYieldOffers() async throws -> EarnDTO.List.Response {
        let request = EarnDTO.List.Request(
            isForEarn: false,
            page: Constants.firstPage,
            limit: Constants.pageLimit,
            type: .yield,
            networkIds: nil,
            apyType: .gross
        )

        do {
            return try await tangemApiService.loadEarnYieldMarkets(requestModel: request)
        } catch {
            if !error.isCancellationError {
                AppLogger.tag("Earn").error("Failed to load the Yield Mode promo offers", error: error)
            }

            throw error
        }
    }
}

// MARK: - Constants

private extension CommonYieldModePromoEarnOffersLoader {
    enum Constants {
        static let firstPage = 1
        static let pageLimit = 3
    }
}
