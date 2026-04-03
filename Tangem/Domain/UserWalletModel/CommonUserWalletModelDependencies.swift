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
import TangemAccounts
import TangemPay

// [REDACTED_TODO_COMMENT]
struct CommonUserWalletModelDependencies {
    let keysRepository: KeysRepository
    let walletModelsManager: WalletModelsManager
    let totalBalanceProvider: TotalBalanceProvider
    let userTokensManager: UserTokensManager
    let nftManager: NFTManager
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    let accountModelsManager: AccountModelsManager

    private var derivationManager: (DerivationManager & DerivationDependenciesConfigurable)?
    private var innerDependencies: InnerDependenciesConfigurable

    init?(userWalletId: UserWalletId, config: UserWalletConfig, keys: WalletKeys) {
        guard let walletManagerFactory = try? config.makeAnyWalletManagerFactory() else {
            return nil
        }

        let shouldLoadExpressAvailability = config.isFeatureVisible(.swapping) || config.isFeatureVisible(.exchange)
        let areHDWalletsSupported = config.hasFeature(.hdWallets)
        let hasTokenSynchronization = config.hasFeature(.multiCurrency)

        let keysRepository = CommonKeysRepository(keys: keys)
        self.keysRepository = keysRepository

        let (userTokensManager, legacyInnerDependencies) = Self.makeUserTokensManager(
            userWalletId: userWalletId,
            config: config,
            areHDWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability
        )
        self.userTokensManager = userTokensManager
        innerDependencies = legacyInnerDependencies

        walletModelsManager = Self.makeWalletModelsManager(
            userWalletId: userWalletId,
            config: config,
            keysRepository: keysRepository,
            userTokensManager: userTokensManager,
            walletManagerFactory: walletManagerFactory
        )
        // Initialized immediately after creation since there are no dependencies to inject
        walletModelsManager.initialize()

        derivationManager = Self.makeDerivationManager(
            keysRepository: keysRepository,
            userTokensManager: userTokensManager,
            areHDWalletsSupported: areHDWalletsSupported
        )

        let remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing

        let tangemPayManager = TangemPayBuilder(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            signer: config.tangemSigner
        )
        .buildTangemPayManager()

        let accountModelsManagerDependencies = Self.makeAccountModelsManagerDependencies(
            userWalletId: userWalletId,
            config: config,
            hasTokenSynchronization: hasTokenSynchronization
        )
        (accountModelsManager, innerDependencies) = Self.makeAccountModelsManager(
            userWalletId: userWalletId,
            config: config,
            walletManagerFactory: walletManagerFactory,
            keysRepository: keysRepository,
            cryptoAccountsRepository: accountModelsManagerDependencies.repository,
            tangemPayManager: tangemPayManager,
            cryptoAccountsNetworkMapper: accountModelsManagerDependencies.mapper,
            archivedCryptoAccountsProvider: accountModelsManagerDependencies.provider,
            derivationManager: derivationManager,
            areHDWalletsSupported: areHDWalletsSupported,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability
        )
        remoteStatusSyncing = accountModelsManagerDependencies.repository

        let userTokensPushNotificationsManager = Self.makeUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager,
            remoteStatusSyncing: remoteStatusSyncing
        )
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        innerDependencies.configure(with: userTokensPushNotificationsManager)

        totalBalanceProvider = Self.makeTotalBalanceProvider(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager
        )

        nftManager = Self.makeNFTManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager
        )

        innerDependencies.configure(with: self)
    }

    func update(from model: UserWalletModel) {
        derivationManager?.configure(with: model)
        innerDependencies.configure(with: model)
    }
}

// MARK: - Factory methods

private extension CommonUserWalletModelDependencies {
    static func makeTotalBalanceProvider(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager
    ) -> TotalBalanceProvider {
        let analyticsLogger = CommonTotalBalanceProviderAnalyticsLogger(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager
        )

        return AccountsAwareTotalBalanceProvider(
            accountModelsManager: accountModelsManager,
            analyticsLogger: analyticsLogger
        )
    }

    static func makeNFTManager(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager
    ) -> NFTManager {
        CommonNFTManager(
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

    static func makeUserTokensPushNotificationsManager(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager,
        remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing
    ) -> (UserTokensPushNotificationsManager & UserTokenListExternalParametersProvider) {
        AccountsAwareUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager,
            remoteStatusSyncing: remoteStatusSyncing
        )
    }

    static func makeWalletModelsManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        keysRepository: KeysRepository,
        userTokensManager: UserTokensManager,
        walletManagerFactory: AnyWalletManagerFactory
    ) -> WalletModelsManager {
        WalletModelsManagerStub()
    }

    static func makeAccountModelsManagerDependencies(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        hasTokenSynchronization: Bool
    ) -> (repository: CommonCryptoAccountsRepository, mapper: CryptoAccountsNetworkMapper, provider: ArchivedCryptoAccountsProvider) {
        let tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.stringValue)
        let auxiliaryDataStorage = CommonCryptoAccountsAuxiliaryDataStorage(
            storageIdentifier: userWalletId.stringValue,
            hasTokenSynchronization: hasTokenSynchronization
        )
        let persistentStorage = CommonCryptoAccountsPersistentStorage(storageIdentifier: userWalletId.stringValue)
        let remoteIdentifierBuilder = CryptoAccountsRemoteIdentifierBuilder(userWalletId: userWalletId)

        let mapper = CryptoAccountsNetworkMapper(
            supportedBlockchains: config.supportedBlockchains,
            remoteIdentifierBuilder: remoteIdentifierBuilder.build(from:)
        )
        let walletsNetworkService = CommonWalletsNetworkService(userWalletId: userWalletId)
        let networkService = CommonCryptoAccountsNetworkService(
            userWalletId: userWalletId,
            mapper: mapper,
            walletsNetworkService: walletsNetworkService
        )
        let defaultAccountFactory = CommonDefaultAccountFactory(
            userWalletId: userWalletId,
            defaultBlockchains: config.defaultBlockchains,
            persistentStorage: persistentStorage
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

        return (cryptoAccountsRepository, mapper, networkService)
    }

    static func makeAccountModelsManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        walletManagerFactory: AnyWalletManagerFactory,
        keysRepository: CommonKeysRepository,
        cryptoAccountsRepository: CommonCryptoAccountsRepository,
        tangemPayManager: TangemPayManager,
        cryptoAccountsNetworkMapper: CryptoAccountsNetworkMapper,
        archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider,
        derivationManager: DerivationManager?,
        areHDWalletsSupported: Bool,
        shouldLoadExpressAvailability: Bool
    ) -> (manager: AccountModelsManager, innerDependencies: InnerDependenciesConfigurable) {
        let hardwareLimitationsUtil = HardwareLimitationsUtil(config: config)
        let walletModelsFactoryProvider = WalletModelsFactoryProvider(
            userWalletId: userWalletId,
            userWalletConfig: config,
            keysProvider: keysRepository,
            derivationManager: derivationManager
        )

        let dependenciesFactory = CommonCryptoAccountDependenciesFactory(
            derivationManager: derivationManager,
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
            walletModelsFactoryProvider: walletModelsFactoryProvider
        )
        let accountModelsManager = CommonAccountModelsManager(
            userWalletId: userWalletId,
            cryptoAccountsRepository: cryptoAccountsRepository,
            tangemPayManager: tangemPayManager,
            archivedCryptoAccountsProvider: archivedCryptoAccountsProvider,
            dependenciesFactory: dependenciesFactory,
            areHDWalletsSupported: areHDWalletsSupported
        )

        // If accounts are enabled, we have to use a special set of dependencies, overriding the existing `innerDependencies`
        let accountsAwareInnerDependencies = AccountsAwareInnerDependencies(
            cryptoAccountsRepository: cryptoAccountsRepository,
            cryptoAccountsNetworkMapper: cryptoAccountsNetworkMapper,
            keysRepository: keysRepository
        )

        return (accountModelsManager, accountsAwareInnerDependencies)
    }

    static func makeUserTokensManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        areHDWalletsSupported: Bool,
        hasTokenSynchronization: Bool,
        shouldLoadExpressAvailability: Bool
    ) -> (manager: UserTokensManager & UserTokensPushNotificationsRemoteStatusSyncing, innerDependencies: InnerDependenciesConfigurable) {
        (LockedUserTokensManager(), DummyInnerDependencies())
    }

    static func makeDerivationManager(
        keysRepository: KeysRepository,
        userTokensManager: UserTokensManager,
        areHDWalletsSupported: Bool
    ) -> (DerivationManager & DerivationDependenciesConfigurable)? {
        guard areHDWalletsSupported else {
            return nil
        }

        return AccountsAwareDerivationManager(keysRepository: keysRepository)
    }
}

// MARK: - Auxiliary types

private extension CommonUserWalletModelDependencies {
    protocol InnerDependenciesConfigurable {
        /// Called 1st.
        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider)
        /// Called 2nd.
        func configure(with dependencies: CommonUserWalletModelDependencies)
        /// Called 3rd.
        func configure(with model: UserWalletModel)
    }

    struct AccountsAwareInnerDependencies: InnerDependenciesConfigurable {
        let cryptoAccountsRepository: CommonCryptoAccountsRepository
        let cryptoAccountsNetworkMapper: CryptoAccountsNetworkMapper
        let keysRepository: CommonKeysRepository

        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider) {
            cryptoAccountsNetworkMapper.externalParametersProvider = externalParametersProvider
        }

        func configure(with dependencies: CommonUserWalletModelDependencies) {
            let derivationManager = dependencies.derivationManager
            let accountModelsManager = dependencies.accountModelsManager
            derivationManager?.configure(with: accountModelsManager)
        }

        func configure(with model: UserWalletModel) {
            cryptoAccountsRepository.configure(with: model)
            keysRepository.configure(with: model)
        }
    }

    struct DummyInnerDependencies: InnerDependenciesConfigurable {
        func configure(with dependencies: CommonUserWalletModelDependencies) {}
        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider) {}
        func configure(with model: UserWalletModel) {}
    }
}
