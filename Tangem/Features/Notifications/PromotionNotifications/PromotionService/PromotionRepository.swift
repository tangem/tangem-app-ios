//
//  PromotionRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

let PromotionsLogger = AppLogger.tag("Promotion")

protocol PromotionRepository {
    func promotionsPublisher(userWalletId: UserWalletId, placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never>

    func loadPromotions(userWalletId: UserWalletId) async
    func loadPromotions(userWalletId: UserWalletId, placeholder: PromotionPlacement) async
    func hidePromotion(userWalletId: UserWalletId, displayId: Int) async
}

private struct PromotionRepositoryKey: InjectionKey {
    static var currentValue: PromotionRepository = CommonPromotionRepository()
}

extension InjectedValues {
    var promotionRepository: PromotionRepository {
        get { Self[PromotionRepositoryKey.self] }
        set { Self[PromotionRepositoryKey.self] = newValue }
    }
}

// MARK: - Async Helpers

extension PromotionRepository {
    private func promotions(
        userWalletId: UserWalletId,
        placeholder: PromotionPlacement
    ) async -> [Promotion] {
        for await promotions in await promotionsPublisher(userWalletId: userWalletId, placeholder: placeholder).values {
            return promotions
        }
        return []
    }

    func promotions(
        userWalletId: UserWalletId,
        placeholder: PromotionPlacement,
        networkId: String,
        tokenAddress: String
    ) async -> [Promotion] {
        await promotions(userWalletId: userWalletId, placeholder: placeholder)
            .filter { $0.matches(networkId: networkId, tokenAddress: tokenAddress) }
    }
}
