//
//  MarketingBannerService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class MarketingBannerService {
    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let balanceConverter: BalanceConverter
    private let language: String?

    init(
        balanceConverter: BalanceConverter = BalanceConverter(),
        language: String? = Locale.current.language.languageCode?.identifier
    ) {
        self.balanceConverter = balanceConverter
        self.language = language
    }
}

extension MarketingBannerService {
    func bannerPublisher(
        for requests: AnyPublisher<SwapMarketingBannerRequest?, Never>
    ) -> AnyPublisher<MarketingBanners, Never> {
        makeBannerPublisher(for: requests, fetch: fetchBanners)
    }

    func bannerPublisher(
        for requests: AnyPublisher<OnrampMarketingBannerRequest?, Never>
    ) -> AnyPublisher<MarketingBanners, Never> {
        makeBannerPublisher(for: requests, fetch: fetchBanners)
    }
}

// MARK: - Private

private extension MarketingBannerService {
    func makeBannerPublisher<Request: Equatable>(
        for requests: AnyPublisher<Request?, Never>,
        fetch: @escaping (Request) async -> MarketingBanners
    ) -> AnyPublisher<MarketingBanners, Never> {
        requests
            .removeDuplicates()
            .map { request -> AnyPublisher<MarketingBanners, Never> in
                guard let request else {
                    return Just(MarketingBanners.empty).eraseToAnyPublisher()
                }

                return Just(request)
                    .asyncMap { await fetch($0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func fetchBanners(for request: SwapMarketingBannerRequest) async -> MarketingBanners {
        let dtoRequest = MarketingCampaignsDTO.Request.swap(
            .init(
                fromNetwork: request.source.networkId,
                fromContractAddress: request.source.contractAddress,
                toNetwork: request.destination.networkId,
                toContractAddress: request.destination.contractAddress,
                language: language
            )
        )

        guard let campaigns = try? await apiService.loadMarketingCampaigns(request: dtoRequest).campaigns else {
            return .empty
        }

        let usdAmount = request.sourceAmount.flatMap { amount in
            request.source.currencyId.flatMap { balanceConverter.convertToUsd(amount, currencyId: $0) }
        }

        return selectBanners(from: campaigns, usdAmount: usdAmount)
    }

    func fetchBanners(for request: OnrampMarketingBannerRequest) async -> MarketingBanners {
        let dtoRequest = MarketingCampaignsDTO.Request.onramp(
            .init(
                toNetwork: request.destination.networkId,
                toContractAddress: request.destination.contractAddress,
                fiatCurrency: request.fiatCurrencyCode,
                language: language
            )
        )

        guard let campaigns = try? await apiService.loadMarketingCampaigns(request: dtoRequest).campaigns else {
            return .empty
        }

        let usdAmount = request.expectedCryptoAmount.flatMap { amount in
            request.destination.currencyId.flatMap { balanceConverter.convertToUsd(amount, currencyId: $0) }
        }

        return selectBanners(from: campaigns, usdAmount: usdAmount)
    }

    func selectBanners(
        from campaigns: [MarketingCampaignsDTO.Campaign],
        usdAmount: Decimal?
    ) -> MarketingBanners {
        MarketingBannerMapper.banners(from: campaigns.filter { satisfiesAmount($0, usd: usdAmount) })
    }

    func satisfiesAmount(_ campaign: MarketingCampaignsDTO.Campaign, usd: Decimal?) -> Bool {
        if campaign.minAmount == nil, campaign.maxAmount == nil {
            return true
        }

        guard let usd else {
            return false
        }

        if let minAmount = campaign.minAmount, usd < minAmount {
            return false
        }

        if let maxAmount = campaign.maxAmount, usd > maxAmount {
            return false
        }

        return true
    }
}
