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
        let cardInfo = userWallet.cardInfo()
        return makeModel(
            cardInfo: cardInfo,
            name: userWallet.name,
            associatedCardIds: userWallet.associatedCardIds
        )
    }

    func makeModel(cardInfo: CardInfo, name: String? = nil, associatedCardIds: Set<String> = []) -> UserWalletModel? {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

        guard let userWalletIdSeed = config.userWalletIdSeed,
              let walletManagerFactory = try? config.makeAnyWalletManagerFactory() else {
            return nil
        }

        let userWalletId = UserWalletId(with: userWalletIdSeed)

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

        let nftManager = CommonNFTManager(
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

        let model = CommonUserWalletModel(
            cardInfo: cardInfo,
            name: name ?? fallbackName(config: config),
            config: config,
            userWalletId: userWalletId,
            associatedCardIds: associatedCardIds,
            walletManagersRepository: walletManagersRepository,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            userTokenListManager: userTokenListManager,
            nftManager: nftManager,
            keysRepository: keysRepository,
            derivationManager: derivationManager,
            totalBalanceProvider: totalBalanceProvider,
            userTokensPushNotificationsManager: userTokensPushNotificationsManager
        )

        derivationManager?.delegate = model
        userTokensManager.keysDerivingProvider = model

        // Set walletModelsManager as the source of addresses for the token list manager & pushNotifyStatus
        userTokenListManager.externalParametersProvider = userTokensPushNotificationsManager

        switch cardInfo.walletData {
        case .visa:
            return VisaUserWalletModel(userWalletModel: model, cardInfo: cardInfo)
        default:
            return model
        }
    }

    private func fallbackName(config: UserWalletConfig) -> String {
        UserWalletNameIndexationHelper.suggestedName(
            config.cardName,
            names: userWalletRepository.models.map(\.name)
        )
    }
}
