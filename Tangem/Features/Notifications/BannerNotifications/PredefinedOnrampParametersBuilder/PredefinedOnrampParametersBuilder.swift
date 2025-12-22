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

    static func loadMoonpayPromotion() {
        Task {
            switch await bannerPromotionService.loadPromotion(programName: moonpayProviderId) {
            case .active:
                isMoonpayPromotionActive.mutate { $0 = true }
            case .expired, .loadingError:
                isMoonpayPromotionActive.mutate { $0 = false }
            }
        }
    }

    static func makeMoonpayPromotionParametersIfActive() -> PredefinedOnrampParameters {
        guard isMoonpayPromotionActive.read() else {
            return .none
        }

        return PredefinedOnrampParameters(preferredValues: .init(providerId: moonpayProviderId))
    }
}
