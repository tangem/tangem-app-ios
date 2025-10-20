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
    let userTokenListManager: UserTokenListManager
    let walletModelsManager: WalletModelsManager
    let derivationManager: CommonDerivationManager?
    let totalBalanceProvider: TotalBalanceProvider
    let userTokensManager: CommonUserTokensManager
    let nftManager: NFTManager
    let accountsWalletModelsAggregator: AccountsWalletModelsAggregating
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
            hasTokenSynchronization: config.hasFeature(.multiCurrency),
            defaultBlockchains: config.defaultBlockchains
        )

        self.userTokenListManager = userTokenListManager

        userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            userTokenListManager: userTokenListManager,
            derivationStyle: config.derivationStyle,
            existingCurves: config.existingCurves,
            persistentBlockchains: config.persistentBlockchains,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: config)
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
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager,
            userTokensManager: userTokensManager
        )

        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        userTokenListManager.externalParametersProvider = userTokensPushNotificationsManager

        // Inline func is used here to avoid long parameter list in the method signature.
        func makeAccountModelsManager() -> AccountModelsManager {
            let tokenItemsRepository = CommonTokenItemsRepository(key: userWalletId.stringValue)
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
            let cryptoAccountsRepository = CommonCryptoAccountsRepository(
                tokenItemsRepository: tokenItemsRepository,
                networkService: networkService,
                persistentStorage: persistentStorage,
                storageController: persistentStorage
            )
            let walletModelsFactory = config.makeWalletModelsFactory(userWalletId: userWalletId)
            let walletModelsManagerFactory = CommonAccountWalletModelsManagerFactory(
                walletManagersRepository: walletManagersRepository,
                walletModelsFactory: walletModelsFactory
            )
            let userTokensManagerFactory = CommonAccountUserTokensManagerFactory(
                userTokenListManager: userTokenListManager,
                derivationStyle: config.derivationStyle,
                derivationManager: derivationManager,
                existingCurves: config.existingCurves,
                persistentBlockchains: config.persistentBlockchains,
                shouldLoadExpressAvailability: shouldLoadExpressAvailability,
                hardwareLimitationsUtil: HardwareLimitationsUtil(config: config)
            )

            let accountModelsManager = CommonAccountModelsManager(
                userWalletId: userWalletId,
                cryptoAccountsRepository: cryptoAccountsRepository,
                archivedCryptoAccountsProvider: networkService,
                walletModelsManagerFactory: walletModelsManagerFactory,
                userTokensManagerFactory: userTokensManagerFactory,
                areHDWalletsSupported: areHDWalletsSupported
            )

            mapper.externalParametersProvider = AccountsAwareUserTokenListExternalParametersProvider(
                accountModelsManager: accountModelsManager,
                userTokensPushNotificationsManager: userTokensPushNotificationsManager
            )

            return accountModelsManager
        }

        accountModelsManager = FeatureProvider.isAvailable(.accounts)
            ? makeAccountModelsManager()
            : DummyCommonAccountModelsManager()

        accountsWalletModelsAggregator = CommonAccountsWalletModelsAggregator(accountModelsManager: accountModelsManager)

        let walletModelsPublisher = FeatureProvider.isAvailable(.accounts)
            ? accountsWalletModelsAggregator.walletModelsPublisher
            : walletModelsManager.walletModelsPublisher

        nftManager = CommonNFTManager(
            userWalletId: userWalletId,
            walletModelsPublisher: walletModelsPublisher,
            walletModelsManager: walletModelsManager,
            analytics: NFTAnalytics.Error(
                logError: { errorCode, description in
                    Analytics.log(event: .nftErrors, params: [.errorCode: errorCode, .errorDescription: description])
                }
            )
        )

        totalBalanceProvider = if FeatureProvider.isAvailable(.accounts) {
            CombineTotalBalanceProvider(
                accountModelsManager: accountModelsManager,
                analyticsLogger: AccountTotalBalanceProviderAnalyticsLogger()
            )
        } else {
            AccountTotalBalanceProvider(
                walletModelsManager: walletModelsManager,
                analyticsLogger: CommonTotalBalanceProviderAnalyticsLogger(
                    userWalletId: userWalletId,
                    walletModelsManager: walletModelsManager
                ),
                derivationManager: derivationManager
            )
        }
    }

    func update(from model: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
        userTokensManager.keysDerivingProvider = model
    }
}
