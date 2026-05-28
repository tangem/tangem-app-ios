//
//  CommonPromotionRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class CommonPromotionRepository {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.promotionProvider) private var promotionProvider: PromotionProvider

    typealias PromotionList = [PromotionPlacement: [Promotion]]

    /// Cached promotions by user wallet id
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

    private var loadPromotionTask: Task<Void, Never>?
    private var userWalletRepositoryEventSubscription: AnyCancellable?

    init() {
        bind()
    }
}

// MARK: - PromotionRepository

extension CommonPromotionRepository: PromotionRepository {
    func promotionsPublisher(userWalletId: UserWalletId, placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never> {
        return promotionsSubject
            .map { $0[userWalletId]?[placeholder] ?? [] }
            .eraseToAnyPublisher()
    }

    func loadPromotions(userWalletId: UserWalletId) async {
        await updatePromotions(for: userWalletId, hasToRefresh: true)?.value
    }

    func loadPromotions(userWalletId: UserWalletId, placeholder: PromotionPlacement) async {
        let walletIdString = userWalletId.stringValue
        let promotions = await loadPromotions(for: walletIdString, placement: placeholder)

        var currentPromotions = promotionsSubject.value[userWalletId] ?? [:]
        currentPromotions[placeholder] = promotions
        promotionsSubject.value[userWalletId] = currentPromotions
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

            _ = try await promotionProvider.hidePromotion(request: request)
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
        let hasCache = promotionsSubject.value[userWalletId] != nil

        guard hasToRefresh || !hasCache else {
            return nil
        }

        loadPromotionTask?.cancel()
        loadPromotionTask = runTask(in: self) { repository in
            PromotionsLogger.info("Start loading promotions for user wallet: \"\(redactedUserWalletId)\"")

            async let mainPromotions = repository.loadPromotions(for: walletIdString, placement: .main)
            async let newsPromotions = repository.loadPromotions(for: walletIdString, placement: .news)
            async let tokenDetailsPromotions = repository.loadPromotions(for: walletIdString, placement: .tokenDetails)
            async let yieldPromotions = repository.loadPromotions(for: walletIdString, placement: .yield)

            let promotions: PromotionList = await [
                .main: mainPromotions,
                .news: newsPromotions,
                .tokenDetails: tokenDetailsPromotions,
                .yield: yieldPromotions,
            ]
            PromotionsLogger.info("Finished loading promotions for user wallet: \"\(redactedUserWalletId)\". Promotions \(promotions.mapValues { $0.map(\.id) })")

            if Task.isCancelled { return }

            guard repository.promotionsSubject.value[userWalletId] != promotions else {
                return
            }

            repository.promotionsSubject.value[userWalletId] = promotions
        }

        return loadPromotionTask
    }

    func loadPromotions(for userWalletId: String, placement: PromotionPlacement) async -> [Promotion] {
        do {
            let request = PromotionsDTO.Load.Request(
                walletId: userWalletId,
                placeholder: placement,
                language: Locale.deviceLanguageCode(withRegion: false)
            )

            let items = try await promotionProvider.loadPromotions(request: request).items
            return items.compactMap(PromotionMapper.mapToPromotion(from:))
        } catch {
            let redactedUserWalletId = "\(userWalletId.prefix(4))...\(userWalletId.suffix(4))"
            PromotionsLogger.error("Loading promotions for user wallet: \"\(redactedUserWalletId)\"", error: error)
            return []
        }
    }
}
