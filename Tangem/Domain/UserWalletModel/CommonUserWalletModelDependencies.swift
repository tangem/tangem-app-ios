//
//  CommonUserWalletModelDependencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine // [REDACTED_TODO_COMMENT]
import TangemFoundation
import TangemNFT
import TangemMobileWalletSdk
import TangemAccounts

struct CommonUserWalletModelDependencies {
    @Injected(\.cryptoAccountsGlobalStateProvider)
    private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider

    let keysRepository: KeysRepository
    let walletModelsManager: WalletModelsManager
    let totalBalanceProvider: TotalBalanceProvider
    let userTokensManager: UserTokensManager
    let nftManager: NFTManager
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    let accountModelsManager: AccountModelsManager

    private var derivationManager: CommonDerivationManager?
    private let dependenciesConfigurator: DependenciesConfigurator

    init?(userWalletId: UserWalletId, config: UserWalletConfig, keys: WalletKeys) {
        guard
            let walletManagerFactory = try? config.makeAnyWalletManagerFactory(),
            let keysRepositoryEncryptionKey = UserWalletEncryptionKey(config: config)
        else {
            return nil
        }

        let shouldLoadExpressAvailability = config.isFeatureVisible(.swapping) || config.isFeatureVisible(.exchange)
        let areHDWalletsSupported = config.hasFeature(.hdWallets)
        let hasTokenSynchronization = config.hasFeature(.multiCurrency)
        let hasAccounts = FeatureProvider.isAvailable(.accounts)

        keysRepository = CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: keysRepositoryEncryptionKey,
            keys: keys
        )

        let userTokensResult = Self.makeUserTokensManager(
            userWalletId: userWalletId,
            config: config,
            areHDWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hasAccounts: hasAccounts
        )

        userTokensManager = userTokensResult.manager
        dependenciesConfigurator = userTokensResult.configurator

        walletModelsManager = Self.makeWalletModelsManager(
            userWalletId: userWalletId,
            config: config,
            keysRepository: keysRepository,
            userTokensManager: userTokensManager,
            walletManagerFactory: walletManagerFactory,
            hasAccounts: hasAccounts
        )
        // Initialized immediately after creation 
        walletModelsManager.initialize()

        derivationManager = areHDWalletsSupported
            ? CommonDerivationManager(keysRepository: keysRepository, userTokensManager: userTokensManager)
            : nil

        // [REDACTED_TODO_COMMENT]
        let userTokensPushNotificationsManager = Self.makeUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            remoteStatusSyncing: userTokensResult.manager,
            derivationManager: derivationManager,
            hasAccounts: hasAccounts
        )

        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        dependenciesConfigurator.configure(with: userTokensPushNotificationsManager)

        // Capture the injected dependency before self is available
        let cryptoAccountsGlobalStateProvider = InjectedValues[\.cryptoAccountsGlobalStateProvider]

        accountModelsManager = Self.makeAccountModelsManager(
            userWalletId: userWalletId,
            config: config,
            walletManagerFactory: walletManagerFactory,
            cryptoAccountsGlobalStateProvider: cryptoAccountsGlobalStateProvider,
            keysRepository: keysRepository,
            userTokensPushNotificationsManager: userTokensPushNotificationsManager,
            areHDWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hasAccounts: hasAccounts
        )

        totalBalanceProvider = Self.makeTotalBalanceProvider(
            userWalletId: userWalletId,
            hasAccounts: hasAccounts,
            accountModelsManager: accountModelsManager,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager
        )

        nftManager = Self.makeNFTManager(
            userWalletId: userWalletId,
            hasAccounts: hasAccounts,
            accountModelsManager: accountModelsManager,
            walletModelsManager: walletModelsManager
        )

        dependenciesConfigurator.configure(with: self)
    }

    func update(from model: UserWalletModel) {
        dependenciesConfigurator.configure(with: model)
    }
}

// MARK: - Factory methods

private extension CommonUserWalletModelDependencies {
    static func makeTotalBalanceProvider(
        userWalletId: UserWalletId,
        hasAccounts: Bool,
        accountModelsManager: AccountModelsManager,
        walletModelsManager: WalletModelsManager,
        derivationManager: CommonDerivationManager?
    ) -> TotalBalanceProvider {
        if hasAccounts {
            return AccountsAwareTotalBalanceProvider(
                accountModelsManager: accountModelsManager,
                analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger()
            )
        }

        return WalletModelsTotalBalanceProvider(
            walletModelsManager: walletModelsManager,
            analyticsLogger: CommonTotalBalanceProviderAnalyticsLogger(
                userWalletId: userWalletId,
                walletModelsManager: walletModelsManager
            ),
            derivationManager: derivationManager
        )
    }

    static func makeNFTManager(
        userWalletId: UserWalletId,
        hasAccounts: Bool,
        accountModelsManager: AccountModelsManager,
        walletModelsManager: WalletModelsManager
    ) -> NFTManager {
        if hasAccounts {
            return CommonNFTManager(
                userWalletId: userWalletId,
                walletModelsPublisher: AccountWalletModelsAggregator.walletModelsPublisher(from: accountModelsManager),
                provideWalletModels: {
                    AccountWalletModelsAggregator.walletModels(from: accountModelsManager)
                },
                analytics: NFTAnalytics.Error(
                    logError: { errorCode, description in
                        Analytics.log(event: .nftErrors, params: [.errorCode: errorCode, .errorDescription: description])
                    }
                )
            )
        }

        return CommonNFTManager(
            userWalletId: userWalletId,
            walletModelsPublisher: walletModelsManager.walletModelsPublisher,
            provideWalletModels: {
                walletModelsManager.walletModels
            },
            analytics: NFTAnalytics.Error(
                logError: { errorCode, description in
                    Analytics.log(event: .nftErrors, params: [.errorCode: errorCode, .errorDescription: description])
                }
            )
        )
    }

    static func makeUserTokensPushNotificationsManager(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing,
        derivationManager: DerivationManager?,
        hasAccounts: Bool
    ) -> (UserTokensPushNotificationsManager & UserTokenListExternalParametersProvider) {
        if hasAccounts {
            // [REDACTED_TODO_COMMENT]
            return StubUserTokensPushNotificationsManager()
        }

        return CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            remoteStatusSyncing: remoteStatusSyncing,
            derivationManager: derivationManager
        )
    }

    static func makeWalletModelsManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        keysRepository: KeysRepository,
        userTokensManager: UserTokensManager,
        walletManagerFactory: AnyWalletManagerFactory,
        hasAccounts: Bool
    ) -> WalletModelsManager {
        if hasAccounts {
            return WalletModelsManagerMock()
        }

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokensManager: userTokensManager,
            walletManagerFactory: walletManagerFactory
        )

        return CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory(userWalletId: userWalletId)
        )
    }

    static func makeAccountModelsManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        walletManagerFactory: AnyWalletManagerFactory,
        cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider,
        keysRepository: KeysRepository,
        userTokensPushNotificationsManager: UserTokensPushNotificationsManager,
        areHDWalletsSupported: Bool,
        hasTokenSynchronization: Bool,
        shouldLoadExpressAvailability: Bool,
        hasAccounts: Bool
    ) -> AccountModelsManager {
        guard hasAccounts else {
            return DummyCommonAccountModelsManager()
        }

        let tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.stringValue)
        let auxiliaryDataStorage = CommonCryptoAccountsAuxiliaryDataStorage(storageIdentifier: userWalletId.stringValue)
        let persistentStorage = CommonCryptoAccountsPersistentStorage(storageIdentifier: userWalletId.stringValue)
        let remoteIdentifierBuilder = CryptoAccountsRemoteIdentifierBuilder(userWalletId: userWalletId)
        let mapper = CryptoAccountsNetworkMapper(
            supportedBlockchains: config.supportedBlockchains,
            remoteIdentifierBuilder: remoteIdentifierBuilder.build(from:)
        )
        let networkService = CommonCryptoAccountsNetworkService(
            userWalletId: userWalletId,
            mapper: mapper
        )
        let defaultAccountFactory = DefaultAccountFactory(
            userWalletId: userWalletId,
            defaultBlockchains: config.defaultBlockchains
        )
        let cryptoAccountsRepository = CommonCryptoAccountsRepository(
            tokenItemsRepository: tokenItemsRepository,
            defaultAccountFactory: defaultAccountFactory,
            networkService: networkService,
            auxiliaryDataStorage: auxiliaryDataStorage,
            persistentStorage: persistentStorage,
            storageController: persistentStorage,
            hasTokenSynchronization: hasTokenSynchronization
        )
        let hardwareLimitationsUtil = HardwareLimitationsUtil(config: config)
        let dependenciesFactory = CommonCryptoAccountDependenciesFactory(
            derivationStyle: config.derivationStyle,
            keysRepository: keysRepository,
            walletManagerFactory: walletManagerFactory,
            existingCurves: config.existingCurves,
            persistentBlockchains: config.persistentBlockchains,
            hardwareLimitationsUtil: hardwareLimitationsUtil,
            areHDWalletsSupported: areHDWalletsSupported,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            userTokensRepositoryProvider: { derivationIndex in
                UserTokensRepositoryAdapter(innerRepository: cryptoAccountsRepository, derivationIndex: derivationIndex)
            },
            walletModelsFactoryProvider: { config.makeWalletModelsFactory(userWalletId: $0) }
        )
        let accountModelsManager = CommonAccountModelsManager(
            userWalletId: userWalletId,
            cryptoAccountsGlobalStateProvider: cryptoAccountsGlobalStateProvider,
            cryptoAccountsRepository: cryptoAccountsRepository,
            archivedCryptoAccountsProvider: networkService,
            dependenciesFactory: dependenciesFactory,
            areHDWalletsSupported: areHDWalletsSupported
        )

        mapper.externalParametersProvider = AccountsAwareUserTokenListExternalParametersProvider(
            accountModelsManager: accountModelsManager,
            userTokensPushNotificationsManager: userTokensPushNotificationsManager
        )

        return accountModelsManager
    }

    static func makeUserTokensManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        areHDWalletsSupported: Bool,
        hasTokenSynchronization: Bool,
        shouldLoadExpressAvailability: Bool,
        hasAccounts: Bool
    ) -> (manager: UserTokensManager & UserTokensPushNotificationsRemoteStatusSyncing, configurator: DependenciesConfigurator) {
        if hasAccounts {
            return (LockedUserTokensManager(), DummyDependenciesConfigurator())
        }

        let hardwareLimitationsUtil = HardwareLimitationsUtil(config: config)

        let userTokenListManager = CommonUserTokenListManager(
            userWalletId: userWalletId.value,
            supportedBlockchains: config.supportedBlockchains,
            hdWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            defaultBlockchains: config.defaultBlockchains
        )

        let userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            userTokenListManager: userTokenListManager,
            derivationStyle: config.derivationStyle,
            existingCurves: config.existingCurves,
            persistentBlockchains: config.persistentBlockchains,
            hardwareLimitationsUtil: hardwareLimitationsUtil
        )

        let dependenciesConfigurator = CommonDependenciesConfigurator(
            userTokensManager: userTokensManager,
            userTokenListManager: userTokenListManager
        )

        return (userTokensManager, dependenciesConfigurator)
    }
}

// MARK: - Auxiliary types

private extension CommonUserWalletModelDependencies {
    @available(iOS, deprecated: 100000.0, message: "Only used when accounts are disabled, will be removed in the future ([REDACTED_INFO])")
    protocol DependenciesConfigurator {
        func configure(with dependencies: CommonUserWalletModelDependencies)
        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider)
        func configure(with model: UserWalletModel)
    }

    @available(iOS, deprecated: 100000.0, message: "Only used when accounts are disabled, will be removed in the future ([REDACTED_INFO])")
    final class CommonDependenciesConfigurator: DependenciesConfigurator {
        init(userTokensManager: CommonUserTokensManager, userTokenListManager: CommonUserTokenListManager) {
            self.userTokensManager = userTokensManager
            self.userTokenListManager = userTokenListManager
        }

        deinit {
            precondition(
                hasConfiguredWithDependencies && hasConfiguredWithExternalParametersProvider && hasConfiguredWithUserWalletModel,
                "Some dependencies haven't been fully configured before use"
            )
        }

        private let userTokensManager: CommonUserTokensManager
        private let userTokenListManager: CommonUserTokenListManager
        private var hasConfiguredWithDependencies = false
        private var hasConfiguredWithExternalParametersProvider = false
        private var hasConfiguredWithUserWalletModel = false

        func configure(with dependencies: CommonUserWalletModelDependencies) {
            // [REDACTED_TODO_COMMENT]
            userTokensManager.derivationManager = dependencies.derivationManager
            userTokensManager.walletModelsManager = dependencies.walletModelsManager
            userTokensManager.sync {}
            hasConfiguredWithDependencies = true
        }

        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider) {
            userTokenListManager.externalParametersProvider = externalParametersProvider
            hasConfiguredWithExternalParametersProvider = true
        }

        func configure(with model: UserWalletModel) {
            userTokensManager.keysDerivingProvider = model
            hasConfiguredWithUserWalletModel = true
        }
    }

    @available(iOS, deprecated: 100000.0, message: "Only used when accounts are disabled, will be removed in the future ([REDACTED_INFO])")
    struct DummyDependenciesConfigurator: DependenciesConfigurator {
        func configure(with dependencies: CommonUserWalletModelDependencies) {}
        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider) {}
        func configure(with model: UserWalletModel) {}
    }

    @available(iOS, deprecated: 100000.0, message: "Temporary stub ([REDACTED_INFO])")
    final class StubUserTokensPushNotificationsManager: UserTokensPushNotificationsManager, UserTokenListExternalParametersProvider {
        private let statusSubject = CurrentValueSubject<UserWalletPushNotifyStatus, Never>(
            .unavailable(reason: .notInitialized, enabledRemote: false)
        )

        var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> {
            statusSubject.eraseToAnyPublisher()
        }

        var status: UserWalletPushNotifyStatus {
            statusSubject.value
        }

        func handleUpdateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {}

        func provideTokenListAddresses() -> [WalletModelId: [String]]? { nil }

        func provideTokenListNotifyStatusValue() -> Bool {
            false
        }
    }
}
