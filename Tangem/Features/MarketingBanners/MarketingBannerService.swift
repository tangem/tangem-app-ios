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
    ) -> AnyPublisher<MarketingBanner?, Never> {
        makeBannerPublisher(for: requests, fetch: fetchBanner)
    }
}

// MARK: - Private

private extension MarketingBannerService {
    func makeBannerPublisher<Request: Equatable>(
        for requests: AnyPublisher<Request?, Never>,
        fetch: @escaping (Request) async -> MarketingBanner?
    ) -> AnyPublisher<MarketingBanner?, Never> {
        requests
            .removeDuplicates()
            .map { request -> AnyPublisher<MarketingBanner?, Never> in
                guard let request else {
                    return Just(nil).eraseToAnyPublisher()
                }

                return Just(request)
                    .asyncMap { await fetch($0) }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    func fetchBanner(for request: SwapMarketingBannerRequest) async -> MarketingBanner? {
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
            return nil
        }

        let usdAmount = request.sourceAmount.flatMap { amount in
            request.source.currencyId.flatMap { balanceConverter.convertToUsd(amount, currencyId: $0) }
        }

        return selectBanner(from: campaigns, providerId: request.providerId, usdAmount: usdAmount)
    }

    func selectBanner(
        from campaigns: [MarketingCampaignsDTO.Campaign],
        providerId: String?,
        usdAmount: Decimal?
    ) -> MarketingBanner? {
        campaigns
            .filter { matches($0, providerId: providerId) }
            .filter { satisfiesAmount($0, usd: usdAmount) }
            .sorted { $0.priority < $1.priority }
            .lazy
            .compactMap { self.makeBanner(from: $0) }
            .first
    }

    func matches(_ campaign: MarketingCampaignsDTO.Campaign, providerId: String?) -> Bool {
        guard let providerIds = campaign.providerIds, !providerIds.isEmpty else {
            return true
        }

        guard let providerId else {
            return false
        }

        return providerIds.contains(providerId)
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

    func makeBanner(from campaign: MarketingCampaignsDTO.Campaign) -> MarketingBanner? {
        guard let text = campaign.banner.text else {
            return nil
        }

        let placement: MarketingBanner.Placement = switch campaign.banner.uiType {
        case .linkedToProvider:
            .linkedToProvider(providerIds: campaign.providerIds ?? [])
        case .standalone, .unknown:
            .standalone
        }

        return MarketingBanner(
            id: campaign.id,
            text: text,
            iconURL: campaign.banner.icon,
            backgroundColorHex: campaign.banner.bgColor,
            placement: placement,
            action: campaign.banner.deeplink.map(MarketingBanner.Action.deeplink),
            isDismissible: campaign.banner.dismissible
        )
    }
}
