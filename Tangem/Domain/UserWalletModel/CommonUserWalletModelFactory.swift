//
//  CommonUserWalletModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

struct CommonUserWalletModelFactory {
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
            name: name ?? UserWalletNameIndexationHelper().suggestedName(userWalletConfig: config),
            config: config,
            userWalletId: userWalletId,
            walletModelsManager: dependencies.walletModelsManager,
            userTokensManager: dependencies.userTokensManager,
            nftManager: dependencies.nftManager,
            keysRepository: dependencies.keysRepository,
            totalBalanceProvider: dependencies.totalBalanceProvider,
            userTokensPushNotificationsManager: dependencies.userTokensPushNotificationsManager,
            accountModelsManager: dependencies.accountModelsManager,
            tangemPayManager: dependencies.tangemPayManager
        )

        dependencies.update(from: commonModel)

        switch walletInfo {
        case .cardWallet(let cardInfo) where cardInfo.walletData.isVisa:
            return VisaUserWalletModel(userWalletModel: commonModel, cardInfo: cardInfo)
        default:
            return commonModel
        }
    }
}
