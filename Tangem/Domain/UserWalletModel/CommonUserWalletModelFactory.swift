//
//  CommonUserWalletModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemMobileWalletSdk
import TangemFoundation

// [REDACTED_TODO_COMMENT]
struct CommonUserWalletModelFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func makeModel(publicData: StoredUserWallet, sensitiveData: StoredUserWallet.SensitiveInfo) -> UserWalletModel? {
        switch (publicData.walletInfo, sensitiveData) {
        case (.cardWallet(let cardInfo), .cardWallet(let keys)):
            var mutableCardInfo = cardInfo
            mutableCardInfo.card.wallets = keys

            return makeModel(
                walletInfo: .cardWallet(mutableCardInfo),
                keys: sensitiveData.asWalletKeys,
                name: publicData.name
            )
        case (.mobileWallet(let info), .mobileWallet(let keys)):
            var mutableInfo = info
            mutableInfo.keys = keys

            return makeModel(
                walletInfo: .mobileWallet(mutableInfo),
                keys: sensitiveData.asWalletKeys,
                name: publicData.name
            )
        default:
            return nil
        }
    }

    func makeModel(
        walletInfo: WalletInfo,
        keys: WalletKeys,
        name: String? = nil
    ) -> UserWalletModel? {
        let config = UserWalletConfigFactory().makeConfig(walletInfo: walletInfo)

        guard
            let userWalletId = UserWalletId(config: config),
            let dependencies = CommonUserWalletModelDependencies(
                userWalletId: userWalletId,
                config: config,
                keys: keys
            )
        else {
            return nil
        }

        let commonModel = CommonUserWalletModel(
            walletInfo: walletInfo,
            name: name ?? fallbackName(config: config),
            config: config,
            userWalletId: userWalletId,
            walletModelsManager: dependencies.walletModelsManager,
            userTokensManager: dependencies.userTokensManager,
            nftManager: dependencies.nftManager,
            keysRepository: dependencies.keysRepository,
            derivationManager: dependencies.derivationManager,
            totalBalanceProvider: dependencies.totalBalanceProvider,
            userTokensPushNotificationsManager: dependencies.userTokensPushNotificationsManager,
            accountModelsManager: dependencies.accountModelsManager
        )

        dependencies.update(from: commonModel)

        switch walletInfo {
        case .cardWallet(let cardInfo):
            switch cardInfo.walletData {
            case .visa:
                return VisaUserWalletModel(
                    userWalletModel: commonModel,
                    cardInfo: cardInfo
                )
            default:
                return commonModel
            }

        default:
            return commonModel
        }
    }

    private func fallbackName(config: UserWalletConfig) -> String {
        guard AppSettings.shared.saveUserWallets else {
            return config.defaultName
        }

        return UserWalletNameIndexationHelper.suggestedName(
            config.defaultName,
            names: userWalletRepository.models.map(\.name)
        )
    }
}

private struct CommonUserWalletModelDependencies {
    let keysRepository: KeysRepository
    let walletModelsManager: WalletModelsManager
    let derivationManager: CommonDerivationManager?
    var totalBalanceProvider: TotalBalanceProvider! // [REDACTED_TODO_COMMENT]
    let userTokensManager: CommonUserTokensManager
    var nftManager: NFTManager! // [REDACTED_TODO_COMMENT]
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    let accountModelsManager: AccountModelsManager

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
        let defaultBlockchains = config.defaultBlockchains

        let keysRepository = CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: keysRepositoryEncryptionKey,
            keys: keys
        )
        self.keysRepository = keysRepository

        let userTokenListManager = CommonUserTokenListManager(
            userWalletId: userWalletId.value,
            supportedBlockchains: config.supportedBlockchains,
            hdWalletsSupported: areHDWalletsSupported,
            hasTokenSynchronization: hasTokenSynchronization,
            defaultBlockchains: defaultBlockchains
        )

        let hardwareLimitationsUtil = HardwareLimitationsUtil(config: config)

        userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            userTokenListManager: userTokenListManager,
            derivationStyle: config.derivationStyle,
            existingCurves: config.existingCurves,
            persistentBlockchains: config.persistentBlockchains,
            hardwareLimitationsUtil: hardwareLimitationsUtil
        )

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokensManager: userTokensManager,
            walletManagerFactory: walletManagerFactory
        )

        walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory(userWalletId: userWalletId)
        )

        let derivationManager = areHDWalletsSupported
            ? CommonDerivationManager(keysRepository: keysRepository, userTokensManager: userTokensManager)
            : nil

        self.derivationManager = derivationManager

        // [REDACTED_TODO_COMMENT]
        userTokensManager.derivationManager = derivationManager
        userTokensManager.walletModelsManager = walletModelsManager
        userTokensManager.sync {}

        let userTokensPushNotificationsManager = CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager, // [REDACTED_TODO_COMMENT]
            userTokensManager: userTokensManager, // [REDACTED_TODO_COMMENT]
            remoteStatusSyncing: userTokensManager, // [REDACTED_TODO_COMMENT]
            derivationManager: derivationManager
        )

        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        userTokenListManager.externalParametersProvider = userTokensPushNotificationsManager

        // Inline func is used here to avoid long parameter list in the method signature.
        func makeAccountModelsManager() -> AccountModelsManager {
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
                defaultBlockchains: defaultBlockchains
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

        accountModelsManager = hasAccounts ? makeAccountModelsManager() : DummyCommonAccountModelsManager()
        nftManager = makeNFTManager(userWalletId: userWalletId, hasAccounts: hasAccounts)
        totalBalanceProvider = makeTotalBalanceProvider(userWalletId: userWalletId, hasAccounts: hasAccounts)
    }

    func makeTotalBalanceProvider(userWalletId: UserWalletId, hasAccounts: Bool) -> TotalBalanceProvider {
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

    func makeNFTManager(userWalletId: UserWalletId, hasAccounts: Bool) -> NFTManager {
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

    func update(from model: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
        userTokensManager.keysDerivingProvider = model
    }
}
