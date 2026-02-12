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
    let tangemPayManager: TangemPayManager

    private var derivationManager: (DerivationManager & DerivationDependenciesConfigurable)?
    private var innerDependencies: InnerDependenciesConfigurable

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

        let (userTokensManager, legacyInnerDependencies) = Self.makeUserTokensManager(
            userWalletId: userWalletId,
            config: config,
            areHDWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hasAccounts: hasAccounts
        )
        self.userTokensManager = userTokensManager
        innerDependencies = legacyInnerDependencies

        walletModelsManager = Self.makeWalletModelsManager(
            userWalletId: userWalletId,
            config: config,
            keysRepository: keysRepository,
            userTokensManager: userTokensManager,
            walletManagerFactory: walletManagerFactory,
            hasAccounts: hasAccounts
        )
        // Initialized immediately after creation since there are no dependencies to inject
        walletModelsManager.initialize()

        derivationManager = Self.makeDerivationManager(
            keysRepository: keysRepository,
            userTokensManager: userTokensManager,
            areHDWalletsSupported: areHDWalletsSupported,
            hasAccounts: hasAccounts
        )

        let remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing

        if hasAccounts {
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
                cryptoAccountsNetworkMapper: accountModelsManagerDependencies.mapper,
                archivedCryptoAccountsProvider: accountModelsManagerDependencies.provider,
                derivationManager: derivationManager,
                areHDWalletsSupported: areHDWalletsSupported,
                shouldLoadExpressAvailability: shouldLoadExpressAvailability
            )
            remoteStatusSyncing = accountModelsManagerDependencies.repository
        } else {
            accountModelsManager = DummyCommonAccountModelsManager()
            remoteStatusSyncing = userTokensManager
        }

        tangemPayManager = TangemPayBuilder(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            signer: config.tangemSigner
        )
        .buildTangemPayManager()

        let userTokensPushNotificationsManager = Self.makeUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            remoteStatusSyncing: remoteStatusSyncing,
            derivationManager: derivationManager,
            hasAccounts: hasAccounts
        )
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        innerDependencies.configure(with: userTokensPushNotificationsManager)

        totalBalanceProvider = Self.makeTotalBalanceProvider(
            userWalletId: userWalletId,
            hasAccounts: hasAccounts,
            accountModelsManager: accountModelsManager,
            tangemPayManager: tangemPayManager,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager
        )

        nftManager = Self.makeNFTManager(
            userWalletId: userWalletId,
            hasAccounts: hasAccounts,
            accountModelsManager: accountModelsManager,
            walletModelsManager: walletModelsManager
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
        hasAccounts: Bool,
        accountModelsManager: AccountModelsManager,
        tangemPayManager: TangemPayManager,
        walletModelsManager: WalletModelsManager,
        derivationManager: DerivationManager?
    ) -> TotalBalanceProvider {
        // Create base provider based on accounts mode
        // Note: WalletModelsTotalBalanceProvider must NOT be created when hasAccounts is true,
        // because it uses derivationManager.hasPendingDerivations which crashes for AccountsAwareDerivationManager
        let baseProvider: TotalBalanceProvider = hasAccounts
            ? AccountsAwareTotalBalanceProvider(
                accountModelsManager: accountModelsManager,
                analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger()
            )
            : WalletModelsTotalBalanceProvider(
                walletModelsManager: walletModelsManager,
                analyticsLogger: CommonTotalBalanceProviderAnalyticsLogger(
                    userWalletId: userWalletId,
                    walletModelsManager: walletModelsManager
                ),
                derivationManager: derivationManager
            )

        return TangemPayAwareTotalBalanceProvider(
            totalBalanceProvider: baseProvider,
            tangemPayTotalBalanceProvider: TangemPayTotalBalanceProvider(tangemPayManager: tangemPayManager)
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
        accountModelsManager: AccountModelsManager,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing,
        derivationManager: DerivationManager?,
        hasAccounts: Bool
    ) -> (UserTokensPushNotificationsManager & UserTokenListExternalParametersProvider) {
        if hasAccounts {
            return AccountsAwareUserTokensPushNotificationsManager(
                userWalletId: userWalletId,
                accountModelsManager: accountModelsManager,
                remoteStatusSyncing: remoteStatusSyncing
            )
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
            return WalletModelsManagerStub()
        }

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokensManager: userTokensManager,
            walletManagerFactory: walletManagerFactory
        )

        // Legacy (non-accounts) flow is semantically equivalent to "main account" -
        // there's only ever one implicit account when the accounts feature is disabled
        return CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory(userWalletId: userWalletId),
            derivationIndex: AccountModelUtils.mainAccountDerivationIndex,
            derivationStyle: config.derivationStyle
        )
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
        keysRepository: KeysRepository,
        cryptoAccountsRepository: CommonCryptoAccountsRepository,
        cryptoAccountsNetworkMapper: CryptoAccountsNetworkMapper,
        archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider,
        derivationManager: DerivationManager?,
        areHDWalletsSupported: Bool,
        shouldLoadExpressAvailability: Bool
    ) -> (manager: AccountModelsManager, innerDependencies: InnerDependenciesConfigurable) {
        let hardwareLimitationsUtil = HardwareLimitationsUtil(config: config)
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
            walletModelsFactoryProvider: { userWalletId in
                config.makeWalletModelsFactory(userWalletId: userWalletId)
            }
        )
        let accountModelsManager = CommonAccountModelsManager(
            userWalletId: userWalletId,
            cryptoAccountsRepository: cryptoAccountsRepository,
            archivedCryptoAccountsProvider: archivedCryptoAccountsProvider,
            dependenciesFactory: dependenciesFactory,
            areHDWalletsSupported: areHDWalletsSupported
        )

        // If accounts are enabled, we have to use a special set of dependencies, overriding the existing `innerDependencies`
        let accountsAwareInnerDependencies = AccountsAwareInnerDependencies(
            cryptoAccountsRepository: cryptoAccountsRepository,
            cryptoAccountsNetworkMapper: cryptoAccountsNetworkMapper
        )

        return (accountModelsManager, accountsAwareInnerDependencies)
    }

    static func makeUserTokensManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        areHDWalletsSupported: Bool,
        hasTokenSynchronization: Bool,
        shouldLoadExpressAvailability: Bool,
        hasAccounts: Bool
    ) -> (manager: UserTokensManager & UserTokensPushNotificationsRemoteStatusSyncing, innerDependencies: InnerDependenciesConfigurable) {
        if hasAccounts {
            return (LockedUserTokensManager(), DummyInnerDependencies())
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

        let innerDependencies = CommonInnerDependencies(
            userTokensManager: userTokensManager,
            userTokenListManager: userTokenListManager
        )

        return (userTokensManager, innerDependencies)
    }

    static func makeDerivationManager(
        keysRepository: KeysRepository,
        userTokensManager: UserTokensManager,
        areHDWalletsSupported: Bool,
        hasAccounts: Bool
    ) -> (DerivationManager & DerivationDependenciesConfigurable)? {
        guard areHDWalletsSupported else {
            return nil
        }

        if hasAccounts {
            return AccountsAwareDerivationManager(keysRepository: keysRepository)
        }

        return CommonDerivationManager(keysRepository: keysRepository, userTokensManager: userTokensManager)
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

    @available(iOS, deprecated: 100000.0, message: "Only used when accounts are disabled, will be removed in the future ([REDACTED_INFO])")
    struct CommonInnerDependencies: InnerDependenciesConfigurable {
        let userTokensManager: CommonUserTokensManager
        let userTokenListManager: CommonUserTokenListManager

        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider) {
            userTokenListManager.externalParametersProvider = externalParametersProvider
        }

        func configure(with dependencies: CommonUserWalletModelDependencies) {
            userTokensManager.derivationManager = dependencies.derivationManager
            userTokensManager.walletModelsManager = dependencies.walletModelsManager
        }

        func configure(with model: UserWalletModel) {
            // The dependency graph is complete at this stage, so it's safe to trigger initial synchronization here
            userTokensManager.sync {}
        }
    }

    struct AccountsAwareInnerDependencies: InnerDependenciesConfigurable {
        let cryptoAccountsRepository: CommonCryptoAccountsRepository
        let cryptoAccountsNetworkMapper: CryptoAccountsNetworkMapper

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
        }
    }

    struct DummyInnerDependencies: InnerDependenciesConfigurable {
        func configure(with dependencies: CommonUserWalletModelDependencies) {}
        func configure(with externalParametersProvider: UserTokenListExternalParametersProvider) {}
        func configure(with model: UserWalletModel) {}
    }
}
