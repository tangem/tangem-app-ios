//
//  CommonSendBaseDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemLocalization

protocol SendApproveDataBuilderInput {
    var selectedPolicy: ApprovePolicy? { get }
    var selectedExpressProvider: ExpressProvider? { get }
    var approveViewModelInput: ApproveViewModelInput? { get }
}

protocol SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { get }
    var bsdkFee: BSDKFee? { get }
    var isFeeIncluded: Bool { get }
}

struct CommonSendBaseDataBuilder {
    private let baseDataInput: SendBaseDataBuilderInput
    private let approveDataInput: SendApproveDataBuilderInput

    private let walletModel: any WalletModel
    private let emailDataProvider: EmailDataProvider
    private let sendReceiveTokensListBuilder: SendReceiveTokensListBuilder
    private let tangemIconProvider: TangemIconProvider

    init(
        baseDataInput: SendBaseDataBuilderInput,
        approveDataInput: SendApproveDataBuilderInput,
        walletModel: any WalletModel,
        emailDataProvider: EmailDataProvider,
        sendReceiveTokensListBuilder: SendReceiveTokensListBuilder,
        tangemIconProvider: TangemIconProvider
    ) {
        self.baseDataInput = baseDataInput
        self.approveDataInput = approveDataInput
        self.walletModel = walletModel
        self.emailDataProvider = emailDataProvider
        self.sendReceiveTokensListBuilder = sendReceiveTokensListBuilder
        self.tangemIconProvider = tangemIconProvider
    }
}

// MARK: - SendBaseDataBuilder

extension CommonSendBaseDataBuilder: SendBaseDataBuilder {
    func makeMailData(transaction: BSDKTransaction, error: SendTxError) -> MailData {
        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            stakingTarget: nil
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> MailData {
        guard let fee = baseDataInput.bsdkFee?.amount else {
            throw SendBaseDataBuilderError.notFound("Fee")
        }

        guard let amount = baseDataInput.bsdkAmount else {
            throw SendBaseDataBuilderError.notFound("Amount")
        }

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee,
            destination: approveTransaction.toContractAddress,
            amount: amount,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            stakingTarget: nil
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> MailData {
        guard let fee = baseDataInput.bsdkFee?.amount else {
            throw SendBaseDataBuilderError.notFound("Fee")
        }

        guard let amount = baseDataInput.bsdkAmount else {
            throw SendBaseDataBuilderError.notFound("Amount")
        }

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee,
            destination: expressTransaction.destinationAddress,
            amount: amount,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: nil,
            stakingTarget: nil
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeSendReceiveTokensList() -> SendReceiveTokensListBuilder {
        return sendReceiveTokensListBuilder
    }
}

// MARK: - SendFeeCurrencyProviderDataBuilder

extension CommonSendBaseDataBuilder: SendFeeCurrencyProviderDataBuilder {
    func makeFeeCurrencyData() -> FeeCurrencyNavigatingDismissOption {
        .init(userWalletId: walletModel.userWalletId, tokenItem: walletModel.feeTokenItem)
    }
}

// MARK: - SendApproveViewModelInputDataBuilder

extension CommonSendBaseDataBuilder: SendApproveViewModelInputDataBuilder {
    func makeExpressApproveViewModelInput() throws -> ExpressApproveViewModel.Input {
        guard let selectedPolicy = approveDataInput.selectedPolicy else {
            throw SendBaseDataBuilderError.notFound("Selected approve policy")
        }

        guard let selectedProvider = approveDataInput.selectedExpressProvider else {
            throw SendBaseDataBuilderError.notFound("Selected provider")
        }

        guard let approveViewModelInput = approveDataInput.approveViewModelInput else {
            throw SendBaseDataBuilderError.notFound("ApproveViewModelInput")
        }

        let settings = ExpressApproveViewModel.Settings(
            subtitle: Localization.givePermissionSwapSubtitle(
                selectedProvider.name,
                walletModel.tokenItem.currencySymbol
            ),
            feeFooterText: Localization.swapGivePermissionFeeFooter,
            tokenItem: walletModel.tokenItem,
            selectedPolicy: selectedPolicy,
            tangemIconProvider: tangemIconProvider
        )

        let feeFormatter = CommonFeeFormatter()

        return ExpressApproveViewModel.Input(
            settings: settings,
            feeFormatter: feeFormatter,
            approveViewModelInput: approveViewModelInput
        )
    }
}
