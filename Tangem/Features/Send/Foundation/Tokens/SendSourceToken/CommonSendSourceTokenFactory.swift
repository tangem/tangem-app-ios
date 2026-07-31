//
//  CommonSendSourceTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

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
            signer: userWalletInfo.signerFactory.makeSigner()
        )

        let allowanceService = AllowanceServiceFactory(
            walletModel: walletModel
        ).makeAllowanceService()

        let emailDataCollectorBuilder = CommonEmailDataCollectorBuilder(
            walletModel: walletModel,
            emailDataProvider: userWalletInfo.emailDataProvider
        )

        let scaledUIAmountMultiplierResolver = makeScaledUIAmountMultiplierResolver()

        let availableBalanceProvider: TokenBalanceProvider
        let fiatAvailableBalanceProvider: TokenBalanceProvider
        switch balanceType {
        case .available:
            availableBalanceProvider = walletModel.availableBalanceProvider
            fiatAvailableBalanceProvider = walletModel.fiatAvailableBalanceProvider
        case .staked(let action):
            let crypto = UnstakingBalanceProvider(tokenItem: walletModel.tokenItem, action: action)
            availableBalanceProvider = crypto
            fiatAvailableBalanceProvider = FiatTokenBalanceProvider(input: walletModel, cryptoBalanceProvider: crypto)
        }

        return CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: walletModel.id,
            header: header,
            feeTokenItem: walletModel.feeTokenItem,
            isCustom: walletModel.isCustom,
            defaultAddressString: walletModel.defaultAddressString,
            availableBalanceProvider: availableBalanceProvider,
            fiatAvailableBalanceProvider: fiatAvailableBalanceProvider,
            allowanceService: allowanceService,
            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider,
            scaledUIAmountMultiplierResolver: scaledUIAmountMultiplierResolver,
            emailDataCollectorBuilder: emailDataCollectorBuilder,
            transactionDispatcherProvider: transactionDispatcherProvider,
            accountModelAnalyticsProvider: walletModel.account,
            tangemIconProvider: CommonTangemIconProvider(config: userWalletInfo.config),
            confirmTransactionPolicy: CommonConfirmTransactionPolicy(userWalletInfo: userWalletInfo),
            isTangemPayAccount: false,
            tokenItem: walletModel.tokenItem,
            fiatItem: fiatItem,
            address: walletModel.defaultAddressString,
            extraId: nil,
            transactionHistoryEnricherFactory: { [weak walletModel] in
                try? await walletModel?
                    .featuresPublisher
                    .first()
                    .async()
                    .transactionHistoryProvider
            }
        )
    }
}

// MARK: - Private

private extension CommonSendSourceTokenFactory {
    func makeScaledUIAmountMultiplierResolver() -> ScaledUIAmountMultiplierResolver? {
        // Scaling is declared by the mint, so only tokens can carry it — a coin has no contract address.
        guard let scaledUIAmountProvider = walletModel.scaledUIAmountProvider,
              let contractAddress = walletModel.tokenItem.contractAddress else {
            return nil
        }

        return ScaledUIAmountMultiplierResolver(
            provider: scaledUIAmountProvider,
            contractAddress: contractAddress
        )
    }
}

enum SendSourceTokenFactoryBalanceType {
    case available
    case staked(action: UnstakingModel.Action)
}
