//
//  MarketingCampaignsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class MarketingCampaignsRepository {
    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let language: String?
    private let campaignsSubject = CurrentValueSubject<[Kind: [MarketingCampaignsDTO.Campaign]], Never>([:])
    private let loadState = OSAllocatedUnfairLock(initialState: LoadState())
    private let storage = CachesDirectoryStorage(file: .cachedMarketingCampaigns)

    init(language: String? = Locale.current.language.languageCode?.identifier) {
        self.language = language
    }
}

// MARK: - Kind

extension MarketingCampaignsRepository {
    enum Kind: String, Hashable {
        case staking
        case yield
    }
}

// MARK: - API

extension MarketingCampaignsRepository {
    func bannersPublisher(for tokenItem: TokenItem, kind: Kind) -> AnyPublisher<MarketingBanners, Never> {
        campaignsSubject
            .map { campaignsByKind in
                let eligible = (campaignsByKind[kind] ?? []).filter { Self.appliesTo($0, tokenItem: tokenItem) }
                return MarketingBannerMapper.banners(from: eligible)
            }
            .eraseToAnyPublisher()
    }

    func loadCampaigns(for kind: Kind) {
        guard FeatureProvider.isAvailable(.marketingBanners) else {
            return
        }

        let shouldLoad = loadState.withLock { state in
            guard !state.loaded.contains(kind), !state.inFlight.contains(kind) else {
                return false
            }

            state.inFlight.insert(kind)
            return true
        }

        guard shouldLoad else {
            return
        }

        Task { [weak self] in
            guard let self else { return }

            defer { loadState.withLock { _ = $0.inFlight.remove(kind) } }

            do {
                let campaigns = try await apiService.loadMarketingCampaigns(request: kind.request(language: language)).campaigns
                await apply(campaigns, for: kind, persist: true)
                loadState.withLock { _ = $0.loaded.insert(kind) }
            } catch {
                if let cached = cachedCampaigns(for: kind) {
                    await apply(cached, for: kind, persist: false)
                }
            }
        }
    }
}

// MARK: - Private

private extension MarketingCampaignsRepository {
    @MainActor
    func apply(_ campaigns: [MarketingCampaignsDTO.Campaign], for kind: Kind, persist: Bool) {
        campaignsSubject.value[kind] = campaigns

        guard persist else {
            return
        }

        let snapshot = Dictionary(uniqueKeysWithValues: campaignsSubject.value.map { ($0.key.rawValue, $0.value) })
        storage.store(value: snapshot)
    }

    func cachedCampaigns(for kind: Kind) -> [MarketingCampaignsDTO.Campaign]? {
        let snapshot: [String: [MarketingCampaignsDTO.Campaign]]? = try? storage.value()
        return snapshot?[kind.rawValue]
    }

    struct LoadState {
        var inFlight: Set<Kind> = []
        var loaded: Set<Kind> = []
    }

    static func appliesTo(_ campaign: MarketingCampaignsDTO.Campaign, tokenItem: TokenItem) -> Bool {
        guard let tokens = campaign.tokens, !tokens.isEmpty else {
            return false
        }

        return tokens.contains { token in
            guard token.networkId == tokenItem.networkId else {
                return false
            }

            switch (token.contractAddress, tokenItem.contractAddress) {
            case (nil, nil):
                return true
            case (.some(let lhs), .some(let rhs)):
                return lhs.caseInsensitiveCompare(rhs) == .orderedSame
            default:
                return false
            }
        }
    }
}

private extension MarketingCampaignsRepository.Kind {
    func request(language: String?) -> MarketingCampaignsDTO.Request {
        switch self {
        case .staking: .staking(language: language)
        case .yield: .yield(language: language)
        }
    }
}
