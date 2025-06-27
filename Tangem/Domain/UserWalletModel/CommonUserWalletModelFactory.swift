//
//  CommonUserWalletModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

struct CommonUserWalletModelFactory {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func makeModel(userWallet: StoredUserWallet) -> UserWalletModel? {
        let walletInfo = userWallet.info

        switch walletInfo.type {
        case .card(let cardInfo):
            return makeCommonUserWalletModel(
                cardInfo: cardInfo,
                name: userWallet.name,
                associatedCardIds: userWallet.associatedCardIds
            )
        case .hot(let hotWalletInfo):
            return makeHotUserWalletModel(hotWalletInfo: hotWalletInfo, name: userWallet.name)
        }
    }

    func makeCommonUserWalletModel(
        cardInfo: CardInfo,
        name: String? = nil,
        associatedCardIds: Set<String> = []
    ) -> UserWalletModel? {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

        guard let dependencies = CommonUserWalletModelDependencies(
            config: config,
            keysRepository: { CommonKeysRepository(with: cardInfo.card.wallets.map(\.walletPublicInfo)) },
            userWalletIdSeed: config.userWalletIdSeed,
        ) else {
            return nil
        }

        let model = CommonUserWalletModel(
            cardInfo: cardInfo,
            name: name ?? fallbackName(config: config),
            config: config,
            userWalletId: dependencies.userWalletId,
            associatedCardIds: associatedCardIds,
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

        dependencies.update(from: model)

        switch cardInfo.walletData {
        case .visa:
            return VisaUserWalletModel(
                userWalletModel: model,
                cardInfo:
                cardInfo
            )
        default:
            return model
        }
    }

    func makeHotUserWalletModel(hotWalletInfo: HotWalletInfo, name: String? = nil) -> UserWalletModel? {
        let config = UserWalletConfigFactory().makeConfig(hotWalletInfo: hotWalletInfo)

        guard let dependencies = CommonUserWalletModelDependencies(
            config: config,
            keysRepository: { CommonKeysRepository(with: hotWalletInfo.wallets.map(\.walletPublicInfo)) },
            userWalletIdSeed: config.userWalletIdSeed,
        ) else {
            return nil
        }

        let hotModel = HotUserWalletModel(
            hotWalletInfo: hotWalletInfo,
            name: name ?? fallbackName(config: config),
            config: config,
            userWalletId: dependencies.userWalletId,
            associatedCardIds: [],
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

        dependencies.update(from: hotModel)

        return hotModel
    }

    private func fallbackName(config: UserWalletConfig) -> String {
        UserWalletNameIndexationHelper.suggestedName(
            config.defaultName,
            names: userWalletRepository.models.map(\.name)
        )
    }
}

private struct CommonUserWalletModelDependencies {
    let userWalletId: UserWalletId
    let keysRepository: KeysRepository
    let userTokenListManager: UserTokenListManager
    let walletManagersRepository: WalletManagersRepository

    let walletModelsManager: WalletModelsManager
    let derivationManager: CommonDerivationManager?
    let totalBalanceProvider: TotalBalanceProvider
    let userTokensManager: CommonUserTokensManager
    let nftManager: NFTManager
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager

    init?(
        config: UserWalletConfig,
        keysRepository: () -> KeysRepository,
        userWalletIdSeed: Data?
    ) {
        guard let userWalletIdSeed,
              let walletManagerFactory = try? config.makeAnyWalletManagerFactory() else {
            return nil
        }

        userWalletId = UserWalletId(with: userWalletIdSeed)
        self.keysRepository = keysRepository()

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
                keysRepository: self.keysRepository,
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

    func update(from model: UserWalletModel & DerivationManagerDelegate) {
        derivationManager?.delegate = model
        userTokensManager.keysDerivingProvider = model
    }
}
