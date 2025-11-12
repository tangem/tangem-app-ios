//
//  CommonUserWalletModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
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
            totalBalanceProvider: dependencies.totalBalanceProvider,
            userTokensPushNotificationsManager: dependencies.userTokensPushNotificationsManager,
            accountModelsManager: dependencies.accountModelsManager
        )

        dependencies.walletModelsManager.initialize()
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
