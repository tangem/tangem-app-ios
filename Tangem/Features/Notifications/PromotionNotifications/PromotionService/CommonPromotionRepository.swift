//
//  CommonPromotionRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@preconcurrency import Combine
import TangemFoundation

class CommonPromotionRepository {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.promoCampaignsRepository) private var promoCampaignsRepository: PromoCampaignsProviding

    typealias PromotionList = [PromotionPlacement: [Promotion]]

    private struct State {
        var promotions: [UserWalletId: PromotionList] = [:]
        var inFlightPromotionLoads: [UserWalletId: UUID] = [:]
        var dismissedPromotionIds: [UserWalletId: Set<Int>] = [:]
    }

    private let isPromoCampaignsEnabled: () -> Bool
    private let state = OSAllocatedUnfairLock(initialState: State())
    private let publishQueue = DispatchQueue(label: "com.tangem.CommonPromotionRepository.publish")

    private let promotionsSubject = CurrentValueSubject<[UserWalletId: PromotionList], Never>([:])

    private var selectedUserWalletId: UserWalletId? {
        userWalletRepository.selectedModel?.userWalletId
    }

    private var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId, Never> {
        userWalletRepository.eventProvider
            .compactMap { event in
                guard case .selected(let userWalletId) = event else {
                    return nil
                }

                return userWalletId
            }
            .prepend(selectedUserWalletId)
            .compactMap(\.self)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var userWalletRepositoryEventSubscription: AnyCancellable?

    init(isPromoCampaignsEnabled: @escaping () -> Bool = { PromoCampaignsAvailability.isEnabled }) {
        self.isPromoCampaignsEnabled = isPromoCampaignsEnabled

        bind()

        if let userWalletId = selectedUserWalletId {
            Task { await loadPromotions(userWalletId: userWalletId) }
        }
    }
}

// MARK: - PromotionRepository

extension CommonPromotionRepository: PromotionRepository {
    func promotionsPublisher(userWalletId: UserWalletId, placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never> {
        let promotions = promotionsSubject
            .map { promotions in
                promotions[userWalletId]?[placeholder] ?? []
            }

        guard isPromoCampaignsEnabled() else {
            return promotions
                .map { promotions in promotions.filter { $0.campaignId == nil } }
                .eraseToAnyPublisher()
        }

        return promotions
            .combineLatest(promoCampaignsRepository.campaignsPublisher(for: userWalletId))
            .map { promotions, campaigns in
                promotions
                    .filter { PromoCampaignBannerMatcher.isVisible(campaignId: $0.campaignId, campaigns: campaigns) }
                    .map { $0.withCampaignName(PromoCampaignBannerMatcher.campaignName(campaignId: $0.campaignId, campaigns: campaigns)) }
            }
            .eraseToAnyPublisher()
    }

    func loadPromotions(userWalletId: UserWalletId) async {
        await updatePromotions(for: userWalletId, hasToRefresh: true)?.value
    }

    func hidePromotion(userWalletId: UserWalletId, displayId: Int) async {
        removePromotion(displayId: displayId, for: userWalletId)

        let walletIdString = userWalletId.stringValue
        let redactedUserWalletId = "\(walletIdString.prefix(4))...\(walletIdString.suffix(4))"

        do {
            let request = PromotionsDTO.Hide.Request(
                displayId: displayId,
                walletId: walletIdString,
                status: .dismissed
            )

            _ = try await tangemApiService.hidePromotion(request: request)
        } catch {
            PromotionsLogger.error("Hiding promotion for user wallet: \"\(redactedUserWalletId)\"", error: error)
        }
    }
}

// MARK: - Private

private extension CommonPromotionRepository {
    func bind() {
        userWalletRepositoryEventSubscription = selectedUserWalletIdPublisher
            .withWeakCaptureOf(self)
            .sink { $0.updatePromotions(for: $1, hasToRefresh: false) }
    }

    @discardableResult
    func updatePromotions(for userWalletId: UserWalletId, hasToRefresh: Bool) -> Task<Void, Never>? {
        let walletIdString = userWalletId.stringValue
        let redactedUserWalletId = "\(walletIdString.prefix(4))...\(walletIdString.suffix(4))"
        let token = UUID()

        let shouldLoad = state { state -> Bool in
            guard hasToRefresh || state.promotions[userWalletId] == nil else {
                return false
            }

            state.inFlightPromotionLoads[userWalletId] = token

            return true
        }

        guard shouldLoad else {
            return nil
        }

        return runTask(in: self) { repository in
            PromotionsLogger.info("Start loading promotions for user wallet: \"\(redactedUserWalletId)\"")

            let promotions: PromotionList = await withTaskGroup(of: (PromotionPlacement, [Promotion]).self) { group in
                for placement in Self.placementsToLoad {
                    group.addTask {
                        let promotions = await repository.loadPromotions(for: walletIdString, placement: placement)
                        return (placement, promotions)
                    }
                }

                var loaded = PromotionList()
                for await (placement, placementPromotions) in group {
                    loaded[placement] = placementPromotions
                }

                return loaded
            }

            PromotionsLogger.info("Finished loading promotions for user wallet: \"\(redactedUserWalletId)\". Promotions \(promotions.mapValues { $0.map(\.id) })")

            repository.store(promotions: promotions, for: userWalletId, token: token)
        }
    }

    func store(promotions: PromotionList, for userWalletId: UserWalletId, token: UUID) {
        state { state in
            // A newer load has claimed the wallet since this one started, so its result is stale.
            guard state.inFlightPromotionLoads[userWalletId] == token else {
                return
            }

            state.inFlightPromotionLoads[userWalletId] = nil

            let dismissedIds = state.dismissedPromotionIds[userWalletId] ?? []
            let visiblePromotions = promotions.mapValues { $0.filter { !dismissedIds.contains($0.id) } }

            guard state.promotions[userWalletId] != visiblePromotions else {
                return
            }

            state.promotions[userWalletId] = visiblePromotions

            let snapshot = state.promotions
            // Enqueued under the lock to keep FIFO order, but sent off it so downstream never runs while it's held.
            publishQueue.async { [promotionsSubject] in
                promotionsSubject.send(snapshot)
            }
        }
    }

    func removePromotion(displayId: Int, for userWalletId: UserWalletId) {
        state { state in
            state.dismissedPromotionIds[userWalletId, default: []].insert(displayId)

            guard let promotions = state.promotions[userWalletId] else {
                return
            }

            let remainingPromotions = promotions.mapValues { $0.filter { $0.id != displayId } }

            guard remainingPromotions != promotions else {
                return
            }

            state.promotions[userWalletId] = remainingPromotions

            let snapshot = state.promotions
            publishQueue.async { [promotionsSubject] in
                promotionsSubject.send(snapshot)
            }
        }
    }

    /// A feed placement costs a request only once its tab can appear at all.
    static var placementsToLoad: [PromotionPlacement] {
        var placements: [PromotionPlacement] = [.main, .paymentAccountMain]

        placements.append(contentsOf: [.crypto, .earn])

        if FeatureProvider.isAvailable(.realAssets) {
            placements.append(.realAssets)
        }

        return placements
    }

    func loadPromotions(for userWalletId: String, placement: PromotionPlacement) async -> [Promotion] {
        do {
            let request = PromotionsDTO.Load.Request(
                walletId: userWalletId,
                placeholder: placement,
                language: Locale.deviceLanguageCode(withRegion: false)
            )

            let items = try await tangemApiService.loadPromotions(request: request).items
            return items.compactMap(PromotionMapper.mapToPromotion(from:))
        } catch {
            let redactedUserWalletId = "\(userWalletId.prefix(4))...\(userWalletId.suffix(4))"
            PromotionsLogger.error("Loading promotions for user wallet: \"\(redactedUserWalletId)\"", error: error)
            return []
        }
    }
}
