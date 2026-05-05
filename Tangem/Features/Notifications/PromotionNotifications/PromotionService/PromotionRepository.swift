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

let PromotionsLogger = AppLogger.tag("Promotions")

protocol PromotionRepository {
    func promotionsPublisher(userWalletId: UserWalletId, placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never>

    func loadPromotions(userWalletId: UserWalletId) async
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
