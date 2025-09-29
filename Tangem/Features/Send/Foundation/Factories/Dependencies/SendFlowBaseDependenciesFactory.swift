//
//  SendFlowBaseDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

protocol SendFlowBaseDependenciesFactory: SendGenericFlowBaseDependenciesFactory {
    var shouldShowFeeSelector: Bool { get }

    var walletModelFeeProvider: WalletModelFeeProvider { get }
    var expressDependenciesFactory: ExpressDependenciesFactory { get }
}

// MARK: - Shared dependencies

extension SendFlowBaseDependenciesFactory {
    // MARK: - Management Model

    func makeSendWithSwapModel(
        swapManager: SwapManager,
        analyticsLogger: any SendAnalyticsLogger,
        predefinedValues: SendModel.PredefinedValues
    ) -> SendModel {
        SendModel(
            userToken: makeSourceToken(),
            transactionSigner: userWalletInfo.signer,
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: walletModelDependenciesProvider.transactionValidator),
            analyticsLogger: analyticsLogger,
            sendReceiveTokenBuilder: makeSendReceiveTokenBuilder(),
            sendAlertBuilder: makeSendAlertBuilder(),
            swapManager: swapManager,
            predefinedValues: predefinedValues
        )
    }

    func makeSourceToken() -> SendSourceToken {
        SendSourceToken(
            wallet: userWalletInfo.name,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            tokenIconInfo: tokenIconInfo,
            fiatItem: makeFiatItem(),
            possibleToConvertToFiat: possibleToConvertToFiat(),
            availableBalanceProvider: walletModelBalancesProvider.availableBalanceProvider,
            fiatAvailableBalanceProvider: walletModelBalancesProvider.fiatAvailableBalanceProvider,
            transactionValidator: walletModelDependenciesProvider.transactionValidator,
            transactionCreator: walletModelDependenciesProvider.transactionCreator,
            transactionDispatcher: transactionDispatcherFactory.makeSendDispatcher()
        )
    }

    func makeSwapManager() -> SwapManager {
        CommonSwapManager(interactor: expressDependenciesFactory.expressInteractor)
    }

    func makeSendAlertBuilder() -> SendAlertBuilder {
        CommonSendAlertBuilder()
    }

    func makeTransactionParametersBuilder() -> TransactionParamsBuilder {
        TransactionParamsBuilder(blockchain: tokenItem.blockchain)
    }

    // MARK: - Fee

    func makeSendWithSwapFeeProvider(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeProvider: SendFeeProvider,
        swapFeeProvider: SendFeeProvider
    ) -> SendFeeProvider {
        SendWithSwapFeeProvider(
            receiveTokenInput: receiveTokenInput,
            sendFeeProvider: sendFeeProvider,
            swapFeeProvider: swapFeeProvider
        )
    }

    func makeSendFeeProvider(input: any SendFeeProviderInput, hasCustomFeeService: Bool) -> SendFeeProvider {
        let options: [FeeOption] = switch (shouldShowFeeSelector, hasCustomFeeService) {
        case (true, true): [.slow, .market, .fast, .custom]
        case (true, false): [.slow, .market, .fast]
        case (false, true): [.market, .custom]
        case (false, false): [.market]
        }

        return CommonSendFeeProvider(
            input: input,
            feeLoader: CommonSendFeeLoader(tokenItem: tokenItem, walletModelFeeProvider: walletModelFeeProvider),
            defaultFeeOptions: options
        )
    }

    func makeSwapFeeProvider(swapManager: SwapManager) -> SendFeeProvider {
        SwapFeeProvider(swapManager: swapManager)
    }

    func makeCustomFeeService(input: CustomFeeServiceInput) -> CustomFeeService? {
        let factory = CustomFeeServiceFactory(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            bitcoinTransactionFeeCalculator: walletModelDependenciesProvider.bitcoinTransactionFeeCalculator
        )

        return factory.makeService(input: input)
    }

    // MARK: - Analytics

    func makeSendAnalyticsLogger(sendType: CommonSendAnalyticsLogger.SendType) -> SendAnalyticsLogger {
        CommonSendAnalyticsLogger(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder(isFixedFee: !shouldShowFeeSelector),
            sendType: sendType
        )
    }

    // MARK: - Notifications

    func makeSendWithSwapNotificationManager(receiveTokenInput: SendReceiveTokenInput) -> SendNotificationManager {
        SendWithSwapNotificationManager(
            receiveTokenInput: receiveTokenInput,
            sendNotificationManager: CommonSendNotificationManager(
                userWalletId: userWalletInfo.id,
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem,
                withdrawalNotificationProvider: walletModelDependenciesProvider.withdrawalNotificationProvider
            ),
            expressNotificationManager: ExpressNotificationManager(
                userWalletId: userWalletInfo.id,
                expressInteractor: expressDependenciesFactory.expressInteractor
            )
        )
    }

    // MARK: - Receive token

    func makeSendReceiveTokenBuilder() -> SendReceiveTokenBuilder {
        SendReceiveTokenBuilder(tokenIconInfoBuilder: TokenIconInfoBuilder(), fiatItem: makeFiatItem())
    }

    // MARK: - Services

    func makeSendQRCodeService() -> SendQRCodeService {
        CommonSendQRCodeService(
            parser: QRCodeParser(
                amountType: tokenItem.amountType,
                blockchain: tokenItem.blockchain,
                decimalCount: tokenItem.decimalCount
            )
        )
    }
}
