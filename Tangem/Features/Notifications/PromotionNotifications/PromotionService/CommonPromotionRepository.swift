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

    typealias PromotionList = [PromotionPlacement: [Promotion]]

    private struct State {
        var promotions: [UserWalletId: PromotionList] = [:]
        var inFlightPromotionLoads: [UserWalletId: UUID] = [:]
    }

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

    init() {
        bind()

        if let userWalletId = selectedUserWalletId {
            Task { await loadPromotions(userWalletId: userWalletId) }
        }
    }
}

// MARK: - PromotionRepository

extension CommonPromotionRepository: PromotionRepository {
    func promotionsPublisher(userWalletId: UserWalletId, placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never> {
        return promotionsSubject
            .map { promotions in
                promotions[userWalletId]?[placeholder] ?? []
            }
            .eraseToAnyPublisher()
    }

    func loadPromotions(userWalletId: UserWalletId) async {
        await updatePromotions(for: userWalletId, hasToRefresh: true)?.value
    }

    func hidePromotion(userWalletId: UserWalletId, displayId: Int) async {
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

            guard state.promotions[userWalletId] != promotions else {
                return
            }

            state.promotions[userWalletId] = promotions

            let snapshot = state.promotions
            // Enqueued under the lock to keep FIFO order, but sent off it so downstream never runs while it's held.
            publishQueue.async { [promotionsSubject] in
                promotionsSubject.send(snapshot)
            }
        }
    }

    /// A feed placement costs a request only once its tab can appear at all.
    static var placementsToLoad: [PromotionPlacement] {
        var placements: [PromotionPlacement] = [.main, .news, .paymentAccountMain]

        guard FeatureProvider.isAvailable(.nativeMarketsShtorka) else {
            return placements
        }

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
