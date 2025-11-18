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
            userTokenListManager: dependencies.userTokenListManager,
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
        let areLongHashesSupported = config.hasFeature(.longHashes)
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
            hasTokenSynchronization: config.hasFeature(.tokenSynchronization),
            defaultBlockchains: config.defaultBlockchains
        )

        self.userTokenListManager = userTokenListManager

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokenListManager: userTokenListManager,
            walletManagerFactory: walletManagerFactory
        )

        walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory(userWalletId: userWalletId)
        )

        let derivationManager = areHDWalletsSupported
            ? CommonDerivationManager(keysRepository: keysRepository, userTokenListManager: userTokenListManager)
            : nil
        self.derivationManager = derivationManager

        totalBalanceProvider = TotalBalanceProvider(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager
        )

        userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            userTokenListManager: userTokenListManager,
            walletModelsManager: walletModelsManager,
            derivationStyle: config.derivationStyle,
            derivationManager: derivationManager,
            existingCurves: config.existingCurves,
            longHashesSupported: areLongHashesSupported
        )

        let userTokensPushNotificationsManager = CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager,
            userTokenListManager: userTokenListManager
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
                shouldLoadExpressAvailability: shouldLoadExpressAvailability,
                areLongHashesSupported: areLongHashesSupported
            )

            return CommonAccountModelsManager(
                userWalletId: userWalletId,
                cryptoAccountsRepository: cryptoAccountsRepository,
                walletModelsManagerFactory: walletModelsManagerFactory,
                userTokensManagerFactory: userTokensManagerFactory,
                areHDWalletsSupported: areHDWalletsSupported
            )
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
    }

    func update(from model: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
        userTokensManager.keysDerivingProvider = model
    }
}
