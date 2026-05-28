//
//  PromotionProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PromotionProvider {
    func loadPromotions(request: PromotionsDTO.Load.Request) async throws -> PromotionsDTO.Load.Response
    func hidePromotion(request: PromotionsDTO.Hide.Request) async throws -> PromotionsDTO.Hide.Response
}

// MARK: - Conformance

extension CommonTangemApiService: PromotionProvider {}
extension FakeTangemApiService: PromotionProvider {}

// MARK: - Dependency Injection

private struct PromotionProviderKey: InjectionKey {
    static var currentValue: PromotionProvider = CommonTangemApiService()
}

extension InjectedValues {
    var promotionProvider: PromotionProvider {
        get { Self[PromotionProviderKey.self] }
        set { Self[PromotionProviderKey.self] = newValue }
    }
}
