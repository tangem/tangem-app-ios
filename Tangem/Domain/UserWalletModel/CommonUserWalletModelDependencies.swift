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
        guard
            let walletManagerFactory = try? config.makeAnyWalletManagerFactory(),
            let keysRepositoryEncryptionKey = UserWalletEncryptionKey(config: config)
        else {
            return nil
        }

        let shouldLoadExpressAvailability = config.isFeatureVisible(.swapping) || config.isFeatureVisible(.exchange)
        let areHDWalletsSupported = config.hasFeature(.hdWallets)
        let hasTokenSynchronization = config.hasFeature(.multiCurrency)
        keysRepository = CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: keysRepositoryEncryptionKey,
            keys: keys
        )

        userTokensManager = LockedUserTokensManager()
        innerDependencies = DummyInnerDependencies()

        walletModelsManager = WalletModelsManagerStub()
        derivationManager = areHDWalletsSupported
            ? AccountsAwareDerivationManager(keysRepository: keysRepository)
            : nil

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
        let userTokensPushNotificationsManager = AccountsAwareUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager,
            remoteStatusSyncing: accountModelsManagerDependencies.repository
        )
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        innerDependencies.configure(with: userTokensPushNotificationsManager)

        let totalBalanceAnalyticsLogger = CommonTotalBalanceProviderAnalyticsLogger(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager
        )
        totalBalanceProvider = AccountsAwareTotalBalanceProvider(
            accountModelsManager: accountModelsManager,
            analyticsLogger: totalBalanceAnalyticsLogger
        )

        nftManager = CommonNFTManager(
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

        innerDependencies.configure(with: self)
    }

    func update(from model: UserWalletModel) {
        derivationManager?.configure(with: model)
        innerDependencies.configure(with: model)
    }
}

// MARK: - Factory methods

private extension CommonUserWalletModelDependencies {
    static func makeAccountModelsManagerDependencies(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        hasTokenSynchronization: Bool
    ) -> (repository: CommonCryptoAccountsRepository, mapper: CryptoAccountsNetworkMapper, provider: ArchivedCryptoAccountsProvider) {
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
        tangemPayManager: TangemPayManager,
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
            tangemPayManager: tangemPayManager,
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
