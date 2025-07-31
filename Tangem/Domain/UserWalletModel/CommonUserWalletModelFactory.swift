//
//  CommonUserWalletModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemHotSdk
import TangemFoundation

struct CommonUserWalletModelFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func makeModel(publicData: StoredUserWallet, sensitiveData: StoredUserWallet.SensitiveInfo) -> UserWalletModel? {
        // CardInfo has to contain wallets due to UserWalletConfig
        switch (publicData.walletInfo, sensitiveData) {
        case (.cardWallet(let cardInfo), .cardWallet(let keys)):
            var mutableCardInfo = cardInfo
            mutableCardInfo.card.wallets = keys

            return makeModel(
                walletInfo: .cardWallet(mutableCardInfo),
                keys: sensitiveData.asWalletKeys,
                name: publicData.name
            )
        default:
            return makeModel(
                walletInfo: publicData.walletInfo,
                keys: sensitiveData.asWalletKeys,
                name: publicData.name
            )
        }
    }

    func makeModel(
        walletInfo: WalletInfo,
        keys: WalletKeys,
        name: String? = nil
    ) -> UserWalletModel? {
        let config = UserWalletConfigFactory().makeConfig(walletInfo: walletInfo)

        guard let userWalletId = UserWalletId(config: config),
              let dependencies = CommonUserWalletModelDependencies(
                  userWalletId: userWalletId,
                  config: config,
                  keys: keys
              ) else {
            return nil
        }

        let commonModel = CommonUserWalletModel(
            walletInfo: walletInfo,
            name: name ?? fallbackName(config: config),
            config: config,
            userWalletId: userWalletId,
            walletManagersRepository: dependencies.walletManagersRepository,
            walletModelsManager: dependencies.walletModelsManager,
            userTokensManager: dependencies.userTokensManager,
            userTokenListManager: dependencies.userTokenListManager,
            nftManager: dependencies.nftManager,
            keysRepository: dependencies.keysRepository,
            derivationManager: dependencies.derivationManager,
            totalBalanceProvider: dependencies.totalBalanceProvider,
            userTokensPushNotificationsManager: dependencies.userTokensPushNotificationsManager
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
    let walletManagersRepository: WalletManagersRepository

    let walletModelsManager: WalletModelsManager
    let derivationManager: CommonDerivationManager?
    let totalBalanceProvider: TotalBalanceProvider
    let userTokensManager: CommonUserTokensManager
    let nftManager: NFTManager
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager

    init?(userWalletId: UserWalletId, config: UserWalletConfig, keys: WalletKeys) {
        guard let walletManagerFactory = try? config.makeAnyWalletManagerFactory(),
              let keysRepositoryEncryptionKey = UserWalletEncryptionKey(config: config) else {
            return nil
        }

        let keysRepository = CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: keysRepositoryEncryptionKey,
            keys: keys
        )

        self.keysRepository = keysRepository

        let userTokenListManager = CommonUserTokenListManager(
            userWalletId: userWalletId.value,
            supportedBlockchains: config.supportedBlockchains,
            hdWalletsSupported: config.hasFeature(.hdWallets),
            hasTokenSynchronization: config.hasFeature(.tokenSynchronization),
            defaultBlockchains: config.defaultBlockchains
        )

        self.userTokenListManager = userTokenListManager

        walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: self.keysRepository,
            userTokenListManager: userTokenListManager,
            walletManagerFactory: walletManagerFactory
        )

        walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory(userWalletId: userWalletId)
        )

        derivationManager = config.hasFeature(.hdWallets)
            ? CommonDerivationManager(
                keysRepository: keysRepository,
                userTokenListManager: userTokenListManager
            )
            : nil

        totalBalanceProvider = TotalBalanceProvider(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager
        )

        userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            shouldLoadExpressAvailability: config.isFeatureVisible(.swapping) || config.isFeatureVisible(.exchange),
            userTokenListManager: userTokenListManager,
            walletModelsManager: walletModelsManager,
            derivationStyle: config.derivationStyle,
            derivationManager: derivationManager,
            existingCurves: config.existingCurves,
            longHashesSupported: config.hasFeature(.longHashes)
        )

        nftManager = CommonNFTManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            analytics: NFTAnalytics.Error(
                logError: { errorCode, description in
                    Analytics.log(event: .nftErrors, params: [.errorCode: errorCode, .errorDescription: description])
                }
            )
        )

        let userTokensPushNotificationsManager = CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager,
            userTokenListManager: userTokenListManager
        )

        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager

        userTokenListManager.externalParametersProvider = userTokensPushNotificationsManager
    }

    func update(from model: UserWalletModel) {
        userTokensManager.keysDerivingProvider = model
    }
}
