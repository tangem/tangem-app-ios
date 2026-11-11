//
//  OnrampFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampFlowBaseDependenciesFactory {
    var sourceToken: SendSourceToken { get }
    var expressDependenciesFactory: ExpressDependenciesFactory { get }
}

extension OnrampFlowBaseDependenciesFactory {
    var userWalletInfo: UserWalletInfo { sourceToken.userWalletInfo }
    var tokenItem: TokenItem { sourceToken.tokenItem }
}

extension OnrampFlowBaseDependenciesFactory {
    // MARK: - Analytics

    func makeOnrampSendAnalyticsLogger(source: SendCoordinator.Source) -> OnrampSendAnalyticsLogger {
        CommonOnrampSendAnalyticsLogger(
            tokenItem: tokenItem,
            source: source,
            accountModelAnalyticsProvider: sourceToken.accountModelAnalyticsProvider
        )
    }

    // MARK: - OnrampDependencies

    func makeOnrampDependencies(preferredValues: PreferredValues) -> (
        manager: OnrampManager,
        repository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        isCountryByIPEnabled: Bool
    ) {
        let apiProvider = expressDependenciesFactory.expressAPIProvider
        let factory = TangemExpressFactory()
        let isCountryByIPEnabled = FeatureProvider.isAvailable(.onrampCountryByIP)
        let repository: OnrampRepository = isCountryByIPEnabled
            ? factory.makeCountryByIPOnrampRepository(userCurrencyStore: InjectedValues[\.onrampUserCurrencyStore])
            : expressDependenciesFactory.onrampRepository

        let dataRepository = factory.makeOnrampDataRepository(expressAPIProvider: apiProvider)

        let analyticsLogger = CommonExpressAnalyticsLogger(tokenItem: tokenItem)
        let manager = factory.makeOnrampManager(
            expressAPIProvider: apiProvider,
            onrampRepository: repository,
            dataRepository: dataRepository,
            analyticsLogger: analyticsLogger,
            providerItemSorter: ProviderItemSorterByOnrampProviderExpectedAmount(),
            preferredValues: preferredValues
        )

        return (
            manager: manager,
            repository: repository,
            dataRepository: dataRepository,
            isCountryByIPEnabled: isCountryByIPEnabled
        )
    }

    // MARK: - Managment Model

    func makeOnrampModel(
        onrampManager: some OnrampManager,
        onrampDataRepository: some OnrampDataRepository,
        onrampRepository: some OnrampRepository,
        analyticsLogger: some OnrampSendAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer,
        isCountryByIPEnabled: Bool,
        predefinedValues: OnrampModel.PredefinedValues
    ) -> OnrampModel {
        OnrampModel(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            defaultAddressString: sourceToken.defaultAddressString,
            onrampManager: onrampManager,
            onrampDataRepository: onrampDataRepository,
            onrampRepository: onrampRepository,
            analyticsLogger: analyticsLogger,
            autoupdatingTimer: autoupdatingTimer,
            redirectSettingsBuilder: OnrampRedirectSettingsBuilder(),
            transactionHistoryEnricherFactory: { [sourceToken] in await sourceToken.transactionHistoryEnricher },
            isCountryByIPEnabled: isCountryByIPEnabled,
            predefinedValues: predefinedValues
        )
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    // MARK: - Notifications

    func makeOnrampNotificationManager(input: OnrampNotificationManagerInput, delegate: NotificationTapDelegate) -> OnrampNotificationManager {
        CommonOnrampNotificationManager(input: input, delegate: delegate)
    }

    func makeOnrampMarketingBannerManager() -> OnrampMarketingBannerManager {
        OnrampMarketingBannerManager(userWalletId: userWalletInfo.id)
    }
}
