//
//  PromotionRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol PromotionRepository {
    func promotionsPublisher(placeholder: PromotionPlacement) -> AnyPublisher<[Promotion], Never>

    func loadPromotions() async
    func hidePromotion(displayId: Int) async throws
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
