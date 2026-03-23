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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let promotionsSubject = CurrentValueSubject<[PromotionPlacement: [Promotion]], Never>([:])

    private var loadPromotionTask: Task<Void, Never>?
    private var userWalletRepositoryEventSubscription: AnyCancellable?

    init() {
        bind()

        Task { await loadPromotions() }
    }
}

// MARK: - PromotionRepository

extension CommonPromotionRepository: PromotionRepository {
    func promotionsPublisher(placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never> {
        promotionsSubject.map { $0[placeholder, default: []] }.eraseToAnyPublisher()
    }

    func loadPromotions() async {
        guard let walletId = userWalletRepository.selectedModel?.userWalletId else {
            promotionsSubject.send([:])
            return
        }

        await updatePromotions(for: walletId).value
    }

    func hidePromotion(displayId: Int) async throws {
        guard let userWalletId = userWalletRepository.selectedModel?.userWalletId else {
            return
        }

        let walletId = userWalletId.stringValue
        let request = PromotionsDTO.Hide.Request(
            displayId: displayId,
            walletId: walletId,
            isDismissed: true
        )

        _ = try await tangemApiService.hidePromotion(request: request)
    }
}

// MARK: - Private

private extension CommonPromotionRepository {
    func bind() {
        userWalletRepositoryEventSubscription = userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { repository, event in
                guard case .selected(let userWalletId) = event else {
                    return
                }

                repository.updatePromotions(for: userWalletId)
            }
    }

    @discardableResult
    func updatePromotions(for userWalletId: UserWalletId) -> Task<Void, Never> {
        loadPromotionTask?.cancel()

        let task = runTask(in: self) { repository in
            async let mainPromotions = repository.loadMainPromotions(for: userWalletId)
            async let newsPromotions = repository.loadNewsPromotions(for: userWalletId)

            let promotions: [PromotionPlacement: [Promotion]] = await [
                .main: mainPromotions,
                .news: newsPromotions,
            ]

            if Task.isCancelled { return }

            repository.promotionsSubject.send(promotions)
        }

        loadPromotionTask = task

        return task
    }

    func loadMainPromotions(for userWalletId: UserWalletId) async -> [Promotion] {
        do {
            let walletId = userWalletId.stringValue
            let request = PromotionsDTO.Load.Request(
                walletId: walletId,
                placeholder: .main,
                lang: Locale.current.localizationCode
            )

            return try await tangemApiService.loadPromotions(request: request).items
        } catch {
            return []
        }
    }

    func loadNewsPromotions(for userWalletId: UserWalletId) async -> [Promotion] {
        do {
            let walletId = userWalletId.hashedStringValue
            let request = PromotionsDTO.Load.Request(
                walletId: walletId,
                placeholder: .news,
                lang: Locale.current.localizationCode
            )

            return try await tangemApiService.loadPromotions(request: request).items
        } catch {
            return []
        }
    }
}
