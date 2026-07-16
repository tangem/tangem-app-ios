//
//  CommonSendMailDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemStaking

// MARK: - Inputs

protocol StakingBaseDataBuilderInput: SendBaseDataBuilderInput {
    var stakingActionType: StakingAction.ActionType? { get }
    var target: StakingTargetInfo? { get }
}

protocol SendBaseDataBuilderInput {
    var bsdkAmount: BSDKAmount? { get }
    var bsdkFee: BSDKFee? { get }
    var isFeeIncluded: Bool { get }
}

// MARK: - CommonSendMailDataBuilder

struct CommonSendMailDataBuilder {
    private let baseDataInput: SendBaseDataBuilderInput
    private let sourceTokenInput: SendSourceTokenInput
    // Swap-only inputs used to pre-fill the support chat; nil for non-swap flows.
    private let receiveTokenInput: SendReceiveTokenInput?
    private let providersInput: SendSwapProvidersInput?

    private var stakingDataInput: StakingBaseDataBuilderInput? {
        baseDataInput as? StakingBaseDataBuilderInput
    }

    init(
        baseDataInput: SendBaseDataBuilderInput,
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenInput: SendReceiveTokenInput? = nil,
        providersInput: SendSwapProvidersInput? = nil
    ) {
        self.baseDataInput = baseDataInput
        self.sourceTokenInput = sourceTokenInput
        self.receiveTokenInput = receiveTokenInput
        self.providersInput = providersInput
    }
}

// MARK: - Private

private extension CommonSendMailDataBuilder {
    func emailDataCollectorBuilder() throws -> EmailDataCollectorBuilder {
        try sourceTokenInput.sourceToken.get().emailDataCollectorBuilder
    }

    func emailRecipient() throws -> String {
        let sourceToken = try sourceTokenInput.sourceToken.get()
        return sourceToken.userWalletInfo.emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
    }

    func makeSwapChatDataCollector(expressTransaction: ExpressTransactionData) -> ChatDataCollector {
        guard
            let receiveTokenInput,
            let providersInput,
            let sourceToken = sourceTokenInput.sourceToken.value,
            let receiveToken = try? receiveTokenInput.receiveToken.get(),
            let provider = providersInput.selectedExpressProvider.flatMap({ try? $0.get() })
        else {
            return EmptyChatDataCollector()
        }

        return SwapChatDataCollector(
            userIdentifier: sourceToken.userWalletInfo.id.stringValue.lowercased(),
            fromAddress: expressTransaction.sourceAddress ?? sourceToken.defaultAddressString,
            sentToken: sourceToken.tokenItem.currencySymbol,
            toAddress: expressTransaction.destinationAddress,
            receivedToken: receiveToken.tokenItem.currencySymbol,
            provider: provider.provider.name,
            providerType: provider.provider.type.rawValue.uppercased()
        )
    }
}

// MARK: - SendMailDataBuilder

extension CommonSendMailDataBuilder: SendMailDataBuilder {
    // MARK: - Send transaction methods

    func makeSupportData(transaction: BSDKTransaction, error: SendTxError) throws -> SupportData {
        let emailDataCollector = try emailDataCollectorBuilder().makeMailData(
            transaction: transaction,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            error: error
        )

        return (emailDataCollector: emailDataCollector, chatDataCollector: EmptyChatDataCollector(), recipient: try emailRecipient())
    }

    func makeSupportData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> SupportData {
        guard let fee = baseDataInput.bsdkFee else {
            throw SendMailDataBuilderError.notFound("Fee")
        }

        guard let amount = baseDataInput.bsdkAmount else {
            throw SendMailDataBuilderError.notFound("Amount")
        }

        let emailDataCollector = try emailDataCollectorBuilder().makeMailData(
            approveTransaction: approveTransaction,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            amount: amount,
            fee: fee,
            error: error
        )

        return (emailDataCollector: emailDataCollector, chatDataCollector: EmptyChatDataCollector(), recipient: try emailRecipient())
    }

    func makeSupportData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> SupportData {
        guard let amount = baseDataInput.bsdkAmount else {
            throw SendMailDataBuilderError.notFound("Amount")
        }

        guard let fee = baseDataInput.bsdkFee else {
            throw SendMailDataBuilderError.notFound("Fee")
        }

        let emailDataCollector = try emailDataCollectorBuilder().makeMailData(
            expressTransaction: expressTransaction,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            amount: amount,
            fee: fee,
            error: error
        )

        let chatDataCollector = makeSwapChatDataCollector(expressTransaction: expressTransaction)
        return (emailDataCollector: emailDataCollector, chatDataCollector: chatDataCollector, recipient: try emailRecipient())
    }

    // MARK: - Staking transaction methods

    func makeSupportData(stakingRequestError error: UniversalError) throws -> SupportData {
        guard let fee = baseDataInput.bsdkFee else {
            throw SendMailDataBuilderError.notFound("Fee")
        }

        guard let amount = baseDataInput.bsdkAmount else {
            throw SendMailDataBuilderError.notFound("Amount")
        }

        guard let stakingDataInput = stakingDataInput else {
            throw SendMailDataBuilderError.notFound("Staking data input")
        }

        guard let target = stakingDataInput.target else {
            throw SendMailDataBuilderError.notFound("Staking target")
        }

        let emailDataCollector = try emailDataCollectorBuilder().makeMailData(
            stakingActionType: stakingDataInput.stakingActionType,
            target: target,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            amount: amount,
            fee: fee,
            error: error
        )

        return (emailDataCollector: emailDataCollector, chatDataCollector: EmptyChatDataCollector(), recipient: try emailRecipient())
    }

    func makeSupportData(action: StakingTransactionAction, error: SendTxError) throws -> SupportData {
        guard let stakingDataInput = stakingDataInput else {
            throw SendMailDataBuilderError.notFound("Staking data input")
        }

        guard let target = stakingDataInput.target else {
            throw SendMailDataBuilderError.notFound("Staking target")
        }

        let emailDataCollector = try emailDataCollectorBuilder().makeMailData(
            action: action,
            stakingActionType: stakingDataInput.stakingActionType,
            target: target,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            error: error
        )

        return (emailDataCollector: emailDataCollector, chatDataCollector: EmptyChatDataCollector(), recipient: try emailRecipient())
    }
}
