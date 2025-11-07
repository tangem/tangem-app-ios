//
//  CommonUserWalletModelDependencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNFT
import TangemMobileWalletSdk

// [REDACTED_TODO_COMMENT]
struct CommonUserWalletModelDependencies {
    let keysRepository: KeysRepository
    var walletModelsManager: WalletModelsManager!
    var totalBalanceProvider: TotalBalanceProvider!
    var userTokensManager: (UserTokensManager & UserTokensPushNotificationsRemoteStatusSyncing)!
    var nftManager: NFTManager!
    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager!
    var accountModelsManager: AccountModelsManager!
    private var derivationManager: CommonDerivationManager?
    private var dependenciesConfigurator: DependenciesConfigurator!

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

        (userTokensManager, dependenciesConfigurator) = makeUserTokensManager(
            userWalletId: userWalletId,
            config: config,
            areHDWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hasAccounts: hasAccounts
        )

        walletModelsManager = makeWalletModelsManager(
            userWalletId: userWalletId,
            config: config,
            walletManagerFactory: walletManagerFactory,
            hasAccounts: hasAccounts
        )

        derivationManager = areHDWalletsSupported
            ? CommonDerivationManager(keysRepository: keysRepository, userTokensManager: userTokensManager)
            : nil

        // [REDACTED_TODO_COMMENT]
        let userTokensPushNotificationsManager = CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            remoteStatusSyncing: userTokensManager,
            derivationManager: derivationManager
        )

        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        dependenciesConfigurator.configure(with: userTokensPushNotificationsManager)

        accountModelsManager = makeAccountModelsManager(
            userWalletId: userWalletId,
            config: config,
            walletManagerFactory: walletManagerFactory,
            areHDWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hasAccounts: hasAccounts
        )

        nftManager = makeNFTManager(userWalletId: userWalletId, hasAccounts: hasAccounts)

        totalBalanceProvider = makeTotalBalanceProvider(userWalletId: userWalletId, hasAccounts: hasAccounts)

        dependenciesConfigurator.configure(with: self)
    }

    func update(from model: UserWalletModel) {
        dependenciesConfigurator.configure(with: model)
    }

    // MARK: - Factory methods

    private func makeTotalBalanceProvider(userWalletId: UserWalletId, hasAccounts: Bool) -> TotalBalanceProvider {
        if hasAccounts {
            return CombineTotalBalanceProvider(
                accountModelsManager: accountModelsManager,
                analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger()
            )
        }

        // [REDACTED_TODO_COMMENT]
        return AccountTotalBalanceProvider(
            walletModelsManager: walletModelsManager,
            analyticsLogger: CommonTotalBalanceProviderAnalyticsLogger(
                userWalletId: userWalletId,
                // [REDACTED_TODO_COMMENT]
                walletModelsManager: walletModelsManager
            ),
            derivationManager: derivationManager
        )
    }

    private func makeNFTManager(userWalletId: UserWalletId, hasAccounts: Bool) -> NFTManager {
        let accountsWalletModelsAggregator = CommonAccountsWalletModelsAggregator(accountModelsManager: accountModelsManager)

        let walletModelsPublisher = hasAccounts
            ? accountsWalletModelsAggregator.walletModelsPublisher
            : walletModelsManager.walletModelsPublisher

        return CommonNFTManager(
            userWalletId: userWalletId,
            walletModelsPublisher: walletModelsPublisher,
            walletModelsManager: walletModelsManager, // [REDACTED_TODO_COMMENT]
            analytics: NFTAnalytics.Error(
                logError: { errorCode, description in
                    Analytics.log(event: .nftErrors, params: [.errorCode: errorCode, .errorDescription: description])
                }
            )
        )
    }

    private func makeWalletModelsManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
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

    private func makeUserTokensManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        areHDWalletsSupported: Bool,
        hasTokenSynchronization: Bool,
        shouldLoadExpressAvailability: Bool,
        hasAccounts: Bool
    ) -> (UserTokensManager & UserTokensPushNotificationsRemoteStatusSyncing, DependenciesConfigurator) {
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

    private func makeAccountModelsManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        walletManagerFactory: AnyWalletManagerFactory,
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
                return UserTokensRepositoryAdapter(
                    innerRepository: cryptoAccountsRepository,
                    derivationIndex: derivationIndex
                )
            },
            walletModelsFactoryProvider: { userWalletId in
                return config.makeWalletModelsFactory(userWalletId: userWalletId)
            }
        )
        let accountModelsManager = CommonAccountModelsManager(
            userWalletId: userWalletId,
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
}

// MARK: - Auxiliary types

@available(iOS, deprecated: 100000.0, message: "Only used when accounts are disabled, will be removed in the future ([REDACTED_INFO])")
private extension CommonUserWalletModelDependencies {
    protocol DependenciesConfigurator {
        func configure(with dependencies: CommonUserWalletModelDependencies)
        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider)
        func configure(with model: UserWalletModel)
    }

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

    struct DummyDependenciesConfigurator: DependenciesConfigurator {
        func configure(with dependencies: CommonUserWalletModelDependencies) {}
        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider) {}
        func configure(with model: UserWalletModel) {}
    }
}
