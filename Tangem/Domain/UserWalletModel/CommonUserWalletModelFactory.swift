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

    func makeModel(walletInfo: WalletInfo, keys: WalletKeys, name: String? = nil) -> UserWalletModel? {
        let config = UserWalletConfigFactory().makeConfig(walletInfo: walletInfo)

        guard let userWalletId = UserWalletId(config: config) else {
            return nil
        }

        let dependencies = CommonUserWalletModelDependencies(
            userWalletId: userWalletId,
            walletInfo: walletInfo,
            config: config,
            keys: keys
        )

        let commonModel = CommonUserWalletModel(
            walletInfo: walletInfo,
            name: name ?? UserWalletNameIndexationHelper().suggestedName(userWalletConfig: config),
            config: config,
            userWalletId: userWalletId,
            nftManager: dependencies.nftManager,
            keysRepository: dependencies.keysRepository,
            keysDerivingInteractor: dependencies.keysDerivingInteractor,
            totalBalanceProvider: dependencies.totalBalanceProvider,
            userWalletPushNotificationsManager: dependencies.userWalletPushNotificationsManager,
            priceAlertsSubscriptionsProvider: dependencies.priceAlertsSubscriptionsProvider,
            accountModelsManager: dependencies.accountModelsManager,
            addressBookManager: dependencies.addressBookManager
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
