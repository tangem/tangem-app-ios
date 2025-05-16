//
//  CommonUserWalletModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonUserWalletModelFactory {
    func makeModel(userWallet: StoredUserWallet) -> UserWalletModel? {
        let cardInfo = userWallet.cardInfo()
        return makeModel(cardInfo: cardInfo, associatedCardIds: userWallet.associatedCardIds)
    }

    func makeModel(cardInfo: CardInfo, associatedCardIds: Set<String> = []) -> UserWalletModel? {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard let userWalletIdSeed = config.userWalletIdSeed else {
            return nil
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

        switch cardInfo.walletData {
        case .visa:
            return makeVisaModel(
                cardInfo: cardInfo,
                config: config,
                userWalletId: userWalletId
            )
        default:
            return makeCommonModel(
                cardInfo: cardInfo,
                config: config,
                userWalletId: userWalletId,
                associatedCardIds: associatedCardIds
            )
        }
    }

    private func makeCommonModel(
        cardInfo: CardInfo,
        config: UserWalletConfig,
        userWalletId: UserWalletId,
        associatedCardIds: Set<String>
    ) -> UserWalletModel? {
        guard let walletManagerFactory = try? config.makeAnyWalletManagerFactory() else {
            return nil
        }

        let keysRepository = CommonKeysRepository(with: cardInfo.card.wallets)

        let userTokenListManager = CommonUserTokenListManager(
            userWalletId: userWalletId.value,
            supportedBlockchains: config.supportedBlockchains,
            hdWalletsSupported: config.hasFeature(.hdWallets),
            hasTokenSynchronization: config.hasFeature(.tokenSynchronization),
            defaultBlockchains: config.defaultBlockchains
        )

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokenListManager: userTokenListManager,
            walletManagerFactory: walletManagerFactory
        )

        let walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: config.makeWalletModelsFactory(userWalletId: userWalletId)
        )

        let derivationManager: CommonDerivationManager? = {
            guard config.hasFeature(.hdWallets) else {
                return nil
            }

            let commonDerivationManager = CommonDerivationManager(
                keysRepository: keysRepository,
                userTokenListManager: userTokenListManager
            )

            return commonDerivationManager
        }()

        let totalBalanceProvider = TotalBalanceProvider(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            derivationManager: derivationManager
        )

        let userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            shouldLoadExpressAvailability: config.isFeatureVisible(.swapping) || config.isFeatureVisible(.exchange),
            userTokenListManager: userTokenListManager,
            walletModelsManager: walletModelsManager,
            derivationStyle: config.derivationStyle,
            derivationManager: derivationManager,
            existingCurves: config.existingCurves,
            longHashesSupported: config.hasFeature(.longHashes)
        )

        let nftManager = CommonNFTManager(walletModelsManager: walletModelsManager)

        let model = CommonUserWalletModel(
            cardInfo: cardInfo,
            config: config,
            userWalletId: userWalletId,
            associatedCardIds: associatedCardIds,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            userTokenListManager: userTokenListManager,
            nftManager: nftManager,
            keysRepository: keysRepository,
            derivationManager: derivationManager,
            totalBalanceProvider: totalBalanceProvider
        )

        derivationManager?.delegate = model
        userTokensManager.keysDerivingProvider = model

        return model
    }

    private func makeVisaModel(cardInfo: CardInfo, config: UserWalletConfig, userWalletId: UserWalletId) -> UserWalletModel {
        let keysRepository = CommonKeysRepository(with: cardInfo.card.wallets)
        let walletModelsManager = VisaWalletModelsManager(keysRepository: keysRepository)

        let model = CommonUserWalletModel(
            cardInfo: cardInfo,
            config: config,
            userWalletId: userWalletId,
            associatedCardIds: [],
            walletModelsManager: walletModelsManager,
            userTokensManager: VisaUserTokensManager(),
            userTokenListManager: VisaTokenListManager(),
            nftManager: NotSupportedNFTManager(),
            keysRepository: CommonKeysRepository(with: cardInfo.card.wallets),
            derivationManager: nil,
            totalBalanceProvider: TotalBalanceProvider(
                userWalletId: userWalletId,
                walletModelsManager: walletModelsManager,
                derivationManager: nil
            )
        )

        return VisaUserWalletModel(userWalletModel: model, cardInfo: cardInfo)
    }
}
