//
//  GlobalServicesContext.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.wcService) private var wcService: any WCService
    @Injected(\.walletConnectService) private var walletConnectService: any OldWalletConnectService
    @Injected(\.analyticsContext) var analyticsContext: AnalyticsContext

    init() {}

    func resetServices() {
        walletConnectService.reset()
        analyticsContext.clearContext()
    }

    func stopAnalyticsSession() {
        analyticsContext.clearSession()
    }

    func initializeServices(userWalletModel: UserWalletModel) {
        analyticsContext.setupContext(with: userWalletModel.analyticsContextData)
        tangemApiService.setAuthData(userWalletModel.tangemApiAuthData)

        if FeatureProvider.isAvailable(.walletConnectUI) {
            wcService.initialize()
        } else {
            walletConnectService.initialize(with: userWalletModel)
        }
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

    func cleanServicesForWallet(userWalletId: UserWalletId) {
        if FeatureProvider.isAvailable(.walletConnectUI) {
            wcService.disconnectAllSessionsForUserWallet(with: userWalletId.stringValue)
        } else {
            walletConnectService.disconnectAllSessionsForUserWallet(with: userWalletId.stringValue)
        }
    }
}
