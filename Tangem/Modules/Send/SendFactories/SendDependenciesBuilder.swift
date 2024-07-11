//
//  SendDependenciesBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

struct SendDependenciesBuilder {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    func walletName() -> String {
        userWalletModel.name
    }

    func isFeeApproximate() -> Bool {
        walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.amountType)
    }

    func makeTokenIconInfo() -> TokenIconInfo {
        TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    func makeFiatIconURL() -> URL {
        IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func makeSendWalletInfo() -> SendWalletInfo {
        let tokenIconInfo = makeTokenIconInfo()

        return SendWalletInfo(
            walletName: walletName(),
            balanceValue: walletModel.balanceValue,
            balance: Localization.sendWalletBalanceFormat(walletModel.balance, walletModel.fiatBalance),
            blockchain: walletModel.blockchainNetwork.blockchain,
            currencyId: walletModel.tokenItem.currencyId,
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: isFeeApproximate(),
            tokenIconInfo: tokenIconInfo,
            cryptoIconURL: tokenIconInfo.imageURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            amountFractionDigits: walletModel.tokenItem.decimalCount,
            feeFractionDigits: walletModel.feeTokenItem.decimalCount,
            feeAmountType: walletModel.feeTokenItem.amountType,
            canUseFiatCalculation: quotesRepository.quote(for: walletModel.tokenItem) != nil
        )
    }

    func makeCurrencyPickerData() -> SendCurrencyPickerData {
        SendCurrencyPickerData(
            cryptoIconURL: makeTokenIconInfo().imageURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            disabled: walletModel.quote == nil
        )
    }

    func makeFeeOptions() -> [FeeOption] {
        if walletModel.shouldShowFeeSelector {
            return [.slow, .market, .fast]
        }

        return [.market]
    }

    func makeSendTransactionParametersBuilder() -> SendTransactionParametersBuilder {
        SendTransactionParametersBuilder(blockchain: walletModel.tokenItem.blockchain)
    }

    func makeFeeAnalyticsParameterBuilder() -> FeeAnalyticsParameterBuilder {
        FeeAnalyticsParameterBuilder(isFixedFee: makeFeeOptions().count == 1)
    }

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
    }

    func makeSendTransactionDispatcher() -> SendTransactionDispatcher {
        CommonSendTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: userWalletModel.signer
        )
    }

    func makeSendModel(
        sendTransactionDispatcher: any SendTransactionDispatcher,
        predefinedSellParameters: PredefinedSellParameters?,
        router: SendRoutable
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)
        let predefinedValues = mapToPredefinedValues(sellParameters: predefinedSellParameters)

        return SendModel(
            walletModel: walletModel,
            sendTransactionDispatcher: sendTransactionDispatcher,
            feeIncludedCalculator: feeIncludedCalculator,
            predefinedValues: predefinedValues
        )
    }

    func mapToPredefinedValues(sellParameters: PredefinedSellParameters?) -> SendModel.PredefinedValues {
        let destination = sellParameters.map { SendAddress(value: $0.destination, source: .sellProvider) }
        let amount = sellParameters.map { sellParameters in
            let fiatValue = walletModel.tokenItem.currencyId.flatMap { currencyId in
                BalanceConverter().convertToFiat(sellParameters.amount, currencyId: currencyId)
            }

            return SendAmount(type: .typical(crypto: sellParameters.amount, fiat: fiatValue))
        }

        // the additionalField is requried. Other can be optional
        let additionalField: SendDestinationAdditionalField = {
            guard let type = SendDestinationAdditionalFieldType.type(for: walletModel.blockchainNetwork.blockchain) else {
                return .notSupported
            }

            guard let tag = sellParameters?.tag?.nilIfEmpty,
                  let params = try? makeSendTransactionParametersBuilder().transactionParameters(from: tag) else {
                return .empty(type: type)
            }

            return .filled(type: type, value: tag, params: params)
        }()

        return SendModel.PredefinedValues(destination: destination, tag: additionalField, amount: amount)
    }
}
