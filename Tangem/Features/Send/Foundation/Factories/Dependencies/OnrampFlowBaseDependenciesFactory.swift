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
    var feeTokenItem: TokenItem { sourceToken.feeTokenItem }
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
        dataRepository: OnrampDataRepository
    ) {
        let apiProvider = expressDependenciesFactory.expressAPIProvider
        let repository: OnrampRepository = expressDependenciesFactory.onrampRepository

        let factory = TangemExpressFactory()
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
            dataRepository: dataRepository
        )
    }

    // MARK: - Managment Model

    func makeOnrampModel(
        onrampManager: some OnrampManager,
        onrampDataRepository: some OnrampDataRepository,
        onrampRepository: some OnrampRepository,
        analyticsLogger: some OnrampSendAnalyticsLogger,
        autoupdatingTimer: AutoupdatingTimer,
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
            predefinedValues: predefinedValues
        )
    }

    func makeOnrampBaseDataBuilder(
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        onrampRedirectingBuilder: OnrampRedirectingBuilder
    ) -> OnrampRouterDataBuilder {
        CommonOnrampBaseDataBuilder(
            config: userWalletInfo.config,
            onrampRepository: onrampRepository,
            onrampDataRepository: onrampDataRepository,
            onrampRedirectingBuilder: onrampRedirectingBuilder
        )
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    // MARK: - Notifications

    func makeOnrampNotificationManager(input: OnrampNotificationManagerInput, delegate: NotificationTapDelegate) -> OnrampNotificationManager {
        CommonOnrampNotificationManager(input: input, delegate: delegate)
    }
}
