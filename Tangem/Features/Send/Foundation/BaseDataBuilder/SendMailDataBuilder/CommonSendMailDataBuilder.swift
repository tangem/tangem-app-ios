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

    private var stakingDataInput: StakingBaseDataBuilderInput? {
        baseDataInput as? StakingBaseDataBuilderInput
    }

    init(
        baseDataInput: SendBaseDataBuilderInput,
        sourceTokenInput: SendSourceTokenInput
    ) {
        self.baseDataInput = baseDataInput
        self.sourceTokenInput = sourceTokenInput
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
}

// MARK: - SendMailDataBuilder

extension CommonSendMailDataBuilder: SendMailDataBuilder {
    // MARK: - Send transaction methods

    func makeMailData(transaction: BSDKTransaction, error: SendTxError) throws -> MailData {
        let emailDataCollector = try emailDataCollectorBuilder().makeMailData(
            transaction: transaction,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            error: error
        )

        return (dataCollector: emailDataCollector, recipient: try emailRecipient())
    }

    func makeMailData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> MailData {
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

        return (dataCollector: emailDataCollector, recipient: try emailRecipient())
    }

    func makeMailData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> MailData {
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

        return (dataCollector: emailDataCollector, recipient: try emailRecipient())
    }

    // MARK: - Staking transaction methods

    func makeMailData(stakingRequestError error: UniversalError) throws -> MailData {
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

        return (dataCollector: emailDataCollector, recipient: try emailRecipient())
    }

    func makeMailData(action: StakingTransactionAction, error: SendTxError) throws -> MailData {
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

        return (dataCollector: emailDataCollector, recipient: try emailRecipient())
    }
}
