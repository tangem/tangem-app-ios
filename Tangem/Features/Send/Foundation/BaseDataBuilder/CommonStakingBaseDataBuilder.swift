//
//  CommonStakingBaseDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk
import TangemStaking
import TangemFoundation

protocol StakingBaseDataBuilderInput: SendBaseDataBuilderInput {
    var selectedPolicy: ApprovePolicy? { get }
    var approveViewModelInput: ApproveViewModelInput? { get }

    var stakingActionType: StakingAction.ActionType? { get }
    var target: StakingTargetInfo? { get }
}

struct CommonStakingBaseDataBuilder {
    private let input: StakingBaseDataBuilderInput
    private let walletModel: any WalletModel
    private let emailDataProvider: EmailDataProvider
    private let tangemIconProvider: TangemIconProvider

    init(
        input: StakingBaseDataBuilderInput,
        walletModel: any WalletModel,
        emailDataProvider: EmailDataProvider,
        tangemIconProvider: TangemIconProvider
    ) {
        self.input = input
        self.walletModel = walletModel
        self.emailDataProvider = emailDataProvider
        self.tangemIconProvider = tangemIconProvider
    }
}

// MARK: - StakingBaseDataBuilder

extension CommonStakingBaseDataBuilder: StakingBaseDataBuilder {
    func makeMailData(stakingRequestError error: UniversalError) throws -> MailData {
        guard let fee = input.bsdkFee?.amount else {
            throw SendBaseDataBuilderError.notFound("Fee")
        }

        guard let amount = input.bsdkAmount else {
            throw SendBaseDataBuilderError.notFound("Amount")
        }

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee,
            destination: "Staking",
            amount: amount,
            isFeeIncluded: input.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: input.stakingActionType,
            stakingTarget: input.target
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(action: StakingTransactionAction, error: SendTxError) -> MailData {
        let feeValue = action.transactions.reduce(0) { $0 + $1.fee }
        let fee = Amount(with: walletModel.feeTokenItem.blockchain, type: walletModel.feeTokenItem.amountType, value: feeValue)
        let amount = Amount(with: walletModel.tokenItem.blockchain, type: walletModel.tokenItem.amountType, value: action.amount)

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: fee,
            destination: "Staking",
            amount: amount,
            isFeeIncluded: input.isFeeIncluded,
            lastError: .init(error: error),
            stakingAction: input.stakingActionType,
            stakingTarget: input.target
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }
}

// MARK: - SendFeeCurrencyProviderDataBuilder

extension CommonStakingBaseDataBuilder: SendFeeCurrencyProviderDataBuilder {
    func makeFeeCurrencyData() -> FeeCurrencyNavigatingDismissOption {
        .init(userWalletId: walletModel.userWalletId, tokenItem: walletModel.feeTokenItem)
    }
}

// MARK: - SendApproveViewModelInputDataBuilder

extension CommonStakingBaseDataBuilder: SendApproveViewModelInputDataBuilder {
    func makeExpressApproveViewModelInput() async throws -> ExpressApproveViewModel.Input {
        guard let selectedPolicy = input.selectedPolicy else {
            throw SendBaseDataBuilderError.notFound("Selected approve policy")
        }

        guard let approveViewModelInput = input.approveViewModelInput else {
            throw SendBaseDataBuilderError.notFound("ApproveViewModelInput")
        }

        let settings = ExpressApproveViewModel.Settings(
            subtitle: Localization.givePermissionStakingSubtitle(walletModel.tokenItem.currencySymbol),
            feeFooterText: Localization.stakingGivePermissionFeeFooter,
            tokenItem: walletModel.tokenItem,
            selectedPolicy: selectedPolicy,
            tangemIconProvider: tangemIconProvider
        )

        let feeFormatter = CommonFeeFormatter()

        return ExpressApproveViewModel.Input(
            settings: settings,
            feeFormatter: feeFormatter,
            approveViewModelInput: approveViewModelInput,
        )
    }
}
