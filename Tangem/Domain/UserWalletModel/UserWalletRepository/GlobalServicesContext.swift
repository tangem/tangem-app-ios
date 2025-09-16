//
//  GlobalServicesContext.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

// [REDACTED_TODO_COMMENT]
protocol GlobalServicesContext {
    func resetServices()
    func initializeServices(userWalletModel: UserWalletModel)
    func initializeAnalyticsContext(cardInfo: CardInfo)
    func cleanServicesForWallet(userWalletId: UserWalletId)
    func stopAnalyticsSession()
}

private struct GlobalServicesContextKey: InjectionKey {
    static var currentValue: GlobalServicesContext = CommonGlobalServicesContext()
}

extension InjectedValues {
    var globalServicesContext: GlobalServicesContext {
        get { Self[GlobalServicesContextKey.self] }
        set { Self[GlobalServicesContextKey.self] = newValue }
    }
}

class CommonGlobalServicesContext: GlobalServicesContext {
    @Injected(\.wcService) private var wcService: any WCService
    @Injected(\.analyticsContext) var analyticsContext: AnalyticsContext

    init() {}

    func resetServices() {
        analyticsContext.clearContext()
    }

    func stopAnalyticsSession() {
        analyticsContext.clearSession()
    }

    func initializeServices(userWalletModel: UserWalletModel) {
        analyticsContext.setupContext(with: userWalletModel.analyticsContextData)
    }

    /// we can initialize it right after scan for more accurate analytics
    func initializeAnalyticsContext(cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        let userWalletId = UserWalletId(config: config)
        let contextData = AnalyticsContextData(
            card: cardInfo.card,
            productType: config.productType,
            embeddedEntry: config.embeddedBlockchain,
            userWalletId: userWalletId
        )

        analyticsContext.setupContext(with: contextData)
    }

    func cleanServicesForWallet(userWalletId: UserWalletId) {}
}
