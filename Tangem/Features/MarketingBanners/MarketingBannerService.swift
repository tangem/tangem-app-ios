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

struct MarketingBannerAmount: Equatable {
    let value: Decimal
    let currencyId: String
}

extension MarketingBannerService {
    func bannerPublisher(
        for requests: AnyPublisher<SwapMarketingBannerRequest?, Never>,
        amount: AnyPublisher<MarketingBannerAmount?, Never>
    ) -> AnyPublisher<MarketingBanners, Never> {
        makeBannerPublisher(for: requests, amount: amount, fetch: fetchCampaigns)
    }

    func bannerPublisher(
        for requests: AnyPublisher<OnrampMarketingBannerRequest?, Never>,
        amount: AnyPublisher<MarketingBannerAmount?, Never>
    ) -> AnyPublisher<MarketingBanners, Never> {
        makeBannerPublisher(for: requests, amount: amount, fetch: fetchCampaigns)
    }
}

// MARK: - Private

private extension MarketingBannerService {
    func makeBannerPublisher<Request: Equatable>(
        for requests: AnyPublisher<Request?, Never>,
        amount: AnyPublisher<MarketingBannerAmount?, Never>,
        fetch: @escaping (Request) async -> [MarketingCampaignsDTO.Campaign]
    ) -> AnyPublisher<MarketingBanners, Never> {
        let campaigns = requests
            .removeDuplicates()
            .map { request -> AnyPublisher<[MarketingCampaignsDTO.Campaign], Never> in
                guard let request else {
                    return Just([]).eraseToAnyPublisher()
                }

                return Just(request)
                    .asyncMap { await fetch($0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()

        return Publishers.CombineLatest(campaigns, amount.prepend(nil).removeDuplicates())
            .asyncMap { [weak self] campaigns, amount -> MarketingBanners in
                guard let self else {
                    return .empty
                }

                let usdAmount = await usdValue(amount)
                return selectBanners(from: campaigns, usdAmount: usdAmount)
            }
            .eraseToAnyPublisher()
    }

    func fetchCampaigns(for request: SwapMarketingBannerRequest) async -> [MarketingCampaignsDTO.Campaign] {
        let dtoRequest = MarketingCampaignsDTO.Request.swap(
            .init(
                fromNetwork: request.source.networkId,
                fromContractAddress: request.source.contractAddress,
                toNetwork: request.destination.networkId,
                toContractAddress: request.destination.contractAddress,
                language: language
            )
        )

        return (try? await apiService.loadMarketingCampaigns(request: dtoRequest).campaigns) ?? []
    }

    func fetchCampaigns(for request: OnrampMarketingBannerRequest) async -> [MarketingCampaignsDTO.Campaign] {
        let dtoRequest = MarketingCampaignsDTO.Request.onramp(
            .init(
                toNetwork: request.destination.networkId,
                toContractAddress: request.destination.contractAddress,
                fiatCurrency: request.fiatCurrencyCode,
                language: language
            )
        )

        return (try? await apiService.loadMarketingCampaigns(request: dtoRequest).campaigns) ?? []
    }

    func usdValue(_ amount: MarketingBannerAmount?) async -> Decimal? {
        guard let amount else {
            return nil
        }

        return try? await balanceConverter.convertToUsd(amount.value, currencyId: amount.currencyId)
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
