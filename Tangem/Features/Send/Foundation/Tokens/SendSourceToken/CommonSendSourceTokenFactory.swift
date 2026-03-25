//
//  CommonSendSourceTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSendSourceTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    func makeSourceToken(balanceType: SendSourceTokenFactoryBalanceType = .available) -> SendSourceToken {
        let header = TokenHeaderProvider(
            userWalletName: userWalletInfo.name,
            account: walletModel.account
        ).makeHeader()

        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        let transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )

        let allowanceService = AllowanceServiceFactory(
            walletModel: walletModel,
            transactionDispatcherProvider: transactionDispatcherProvider
        ).makeAllowanceService()

        let emailDataCollectorBuilder = CommonEmailDataCollectorBuilder(
            walletModel: walletModel,
            emailDataProvider: userWalletInfo.emailDataProvider
        )

        let availableBalanceProvider: TokenBalanceProvider = switch balanceType {
        case .available: walletModel.availableBalanceProvider
        case .staked: walletModel.stakingBalanceProvider
        }

        let fiatAvailableBalanceProvider: TokenBalanceProvider = switch balanceType {
        case .available: walletModel.fiatAvailableBalanceProvider
        case .staked: walletModel.fiatStakingBalanceProvider
        }

        return CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: walletModel.id,
            header: header,
            feeTokenItem: walletModel.feeTokenItem,
            isFixedFee: !walletModel.shouldShowFeeSelector,
            isCustom: walletModel.isCustom,
            defaultAddressString: walletModel.defaultAddressString,
            availableBalanceProvider: availableBalanceProvider,
            fiatAvailableBalanceProvider: fiatAvailableBalanceProvider,
            allowanceService: allowanceService,
            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider,
            emailDataCollectorBuilder: emailDataCollectorBuilder,
            transactionDispatcherProvider: transactionDispatcherProvider,
            accountModelAnalyticsProvider: walletModel.account,
            tokenItem: walletModel.tokenItem,
            fiatItem: fiatItem,
            address: walletModel.defaultAddressString,
            extraId: nil
        )
    }
}

enum SendSourceTokenFactoryBalanceType {
    case available
    case staked
}
