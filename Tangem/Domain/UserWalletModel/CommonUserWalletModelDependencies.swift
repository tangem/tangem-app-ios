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

struct CommonUserWalletModelDependencies {
    let keysRepository: KeysRepository
    let keysDerivingInteractor: KeysDeriving
    let totalBalanceProvider: TotalBalanceProvider
    let nftManager: NFTManager
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    let accountModelsManager: AccountModelsManager

    private let userWalletModelConfigurableDependencies: UserWalletModelConfigurableDependencies

    init(userWalletId: UserWalletId, walletInfo: WalletInfo, config: UserWalletConfig, keys: WalletKeys) {
        let walletManagerFactory = config.makeAnyWalletManagerFactory()

        let shouldLoadExpressAvailability = config.isFeatureVisible(.swapping) || config.isFeatureVisible(.exchange)
        let areHDWalletsSupported = config.hasFeature(.hdWallets)
        let hasTokenSynchronization = config.hasFeature(.multiCurrency)

        let keysRepository = Self.makeKeysRepository(keys: keys)
        self.keysRepository = keysRepository

        keysDerivingInteractor = Self.makeKeysDeriving(
            walletInfo: walletInfo,
            userWalletId: userWalletId,
            config: config
        )

        let derivationManager = Self.makeDerivationManager(
            keysRepository: keysRepository,
            areHDWalletsSupported: areHDWalletsSupported
        )

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

        accountModelsManager = Self.makeAccountModelsManager(
            userWalletId: userWalletId,
            config: config,
            walletManagerFactory: walletManagerFactory,
            keysRepository: keysRepository,
            keysDerivingInteractor: keysDerivingInteractor,
            cryptoAccountsRepository: accountModelsManagerDependencies.cryptoAccountsRepository,
            tangemPayManager: tangemPayManager,
            cryptoAccountsNetworkMapper: accountModelsManagerDependencies.networkMapper,
            archivedCryptoAccountsProvider: accountModelsManagerDependencies.archivedCryptoAccountsProvider,
            derivationManager: derivationManager,
            areHDWalletsSupported: areHDWalletsSupported,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability
        )
        derivationManager?.configure(with: accountModelsManager)

        let userTokensPushNotificationsManager = Self.makeUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager,
            remoteStatusSyncing: accountModelsManagerDependencies.cryptoAccountsRepository
        )
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        accountModelsManagerDependencies.networkMapper.externalParametersProvider = userTokensPushNotificationsManager

        totalBalanceProvider = Self.makeTotalBalanceProvider(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager
        )

        nftManager = Self.makeNFTManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager
        )

        userWalletModelConfigurableDependencies = UserWalletModelConfigurableDependencies(
            derivationManager: derivationManager,
            keysRepository: keysRepository,
            cryptoAccountsRepository: accountModelsManagerDependencies.cryptoAccountsRepository
        )
    }

    func update(from model: UserWalletModel) {
        userWalletModelConfigurableDependencies.derivationManager?.configure(with: model)
        userWalletModelConfigurableDependencies.cryptoAccountsRepository.configure(with: model)
        userWalletModelConfigurableDependencies.keysRepository.configure(with: model)
    }
}

// MARK: - Factory methods

private extension CommonUserWalletModelDependencies {
    static func makeKeysRepository(keys: WalletKeys) -> CommonKeysRepository {
        CommonKeysRepository(keys: keys)
    }

    static func makeKeysDeriving(
        walletInfo: WalletInfo,
        userWalletId: UserWalletId,
        config: UserWalletConfig
    ) -> KeysDeriving {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            return KeysDerivingCardInteractor(with: cardInfo)
        case .mobileWallet:
            return KeysDerivingMobileWalletInteractor(userWalletId: userWalletId, userWalletConfig: config)
        }
    }

    static func makeDerivationManager(
        keysRepository: KeysRepository,
        areHDWalletsSupported: Bool
    ) -> (DerivationManager & DerivationDependenciesConfigurable)? {
        return areHDWalletsSupported ? CommonDerivationManager(keysRepository: keysRepository) : nil
    }

    static func makeAccountModelsManagerDependencies(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        hasTokenSynchronization: Bool
    ) -> AccountModelsManagerDependencies {
        let tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.stringValue)
        let auxiliaryDataStorage = CommonCryptoAccountsAuxiliaryDataStorage(
            storageIdentifier: userWalletId.stringValue,
            hasTokenSynchronization: hasTokenSynchronization
        )
        let persistentStorage = CommonCryptoAccountsPersistentStorage(storageIdentifier: userWalletId.stringValue)
        let remoteIdentifierBuilder = CryptoAccountsRemoteIdentifierBuilder(userWalletId: userWalletId)

        let networkMapper = CryptoAccountsNetworkMapper(
            supportedBlockchains: config.supportedBlockchains,
            remoteIdentifierBuilder: remoteIdentifierBuilder.build(from:)
        )
        let walletsNetworkService = CommonWalletsNetworkService(userWalletId: userWalletId)
        let networkService = CommonCryptoAccountsNetworkService(
            userWalletId: userWalletId,
            mapper: networkMapper,
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
            walletLifecycleObserver: InjectedValues[\.walletLifecycleObserver],
            auxiliaryDataStorage: auxiliaryDataStorage,
            persistentStorage: persistentStorage,
            storageController: persistentStorage,
            hasTokenSynchronization: hasTokenSynchronization
        )

        return AccountModelsManagerDependencies(
            networkMapper: networkMapper,
            cryptoAccountsRepository: cryptoAccountsRepository,
            archivedCryptoAccountsProvider: networkService
        )
    }

    static func makeAccountModelsManager(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        walletManagerFactory: AnyWalletManagerFactory,
        keysRepository: KeysRepository,
        keysDerivingInteractor: KeysDeriving,
        cryptoAccountsRepository: CommonCryptoAccountsRepository,
        tangemPayManager: TangemPayManager,
        cryptoAccountsNetworkMapper: CryptoAccountsNetworkMapper,
        archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider,
        derivationManager: DerivationManager?,
        areHDWalletsSupported: Bool,
        shouldLoadExpressAvailability: Bool
    ) -> AccountModelsManager {
        let hardwareLimitationsUtil = HardwareLimitationsUtil(config: config)

        let transactionHistoryProviderRegistry = CommonTransactionHistoryProviderRegistry()

        let walletModelsFactoryProvider = WalletModelsFactoryProvider(
            userWalletId: userWalletId,
            userWalletConfig: config,
            keysRepository: keysRepository,
            keysDerivingInteractor: keysDerivingInteractor,
            transactionHistoryProviderRegistry: transactionHistoryProviderRegistry
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

        transactionHistoryProviderRegistry.setup(with: accountModelsManager)

        return accountModelsManager
    }

    static func makeUserTokensPushNotificationsManager(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager,
        remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing
    ) -> (UserTokensPushNotificationsManager & UserTokenListExternalParametersProvider) {
        // [REDACTED_TODO_COMMENT]
        return CommonUserWalletPushNotificationsManager(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager,
            remoteStatusSyncing: remoteStatusSyncing,
            notificationPreferencesProvider: NotificationPreferencesProviderStub()
        )
    }

    static func makeTotalBalanceProvider(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager
    ) -> TotalBalanceProvider {
        let analyticsLogger = CommonTotalBalanceProviderAnalyticsLogger(
            userWalletId: userWalletId,
            accountModelsManager: accountModelsManager
        )

        return CommonTotalBalanceProvider(
            accountModelsManager: accountModelsManager,
            analyticsLogger: analyticsLogger
        )
    }

    static func makeNFTManager(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager
    ) -> NFTManager {
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
}

// MARK: - Auxiliary types

private extension CommonUserWalletModelDependencies {
    /// Represents dependencies that are required for `UserWalletModel` but must be configured later when the model is already created.
    /// This is needed to break circular dependencies between `UserWalletModel` and some of its dependencies (e.g. `KeysRepository`).
    struct UserWalletModelConfigurableDependencies {
        let derivationManager: DerivationDependenciesConfigurable?
        let keysRepository: CommonKeysRepository
        let cryptoAccountsRepository: CommonCryptoAccountsRepository
    }

    /// Represents dependencies related to crypto accounts models that are required for `AccountModelsManager` initialization,
    /// but must be created together due to their interdependencies.
    struct AccountModelsManagerDependencies {
        let networkMapper: CryptoAccountsNetworkMapper
        let cryptoAccountsRepository: CommonCryptoAccountsRepository
        let archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider
    }
}
