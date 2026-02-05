//
//  PredefinedOnrampParametersBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

enum PredefinedOnrampParametersBuilder {
    @Injected(\.bannerPromotionService)
    private static var bannerPromotionService: BannerPromotionService
    private static let moonpayProviderId: String = "moonpay"
    private static var isMoonpayPromotionActive: ThreadSafeContainer<Bool> = .init(false)

    static func loadMoonpayPromotion() {}

    static func makeMoonpayPromotionParametersIfActive() -> PredefinedOnrampParameters {
        guard isMoonpayPromotionActive.read() else {
            return .none
        }

        return PredefinedOnrampParameters(preferredValues: .init(providerId: moonpayProviderId))
    }
}
