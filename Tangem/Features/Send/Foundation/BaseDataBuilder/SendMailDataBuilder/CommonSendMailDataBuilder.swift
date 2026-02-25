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
    private let emailDataCollectorBuilder: EmailDataCollectorBuilder
    private let emailDataProvider: EmailDataProvider

    private var stakingDataInput: StakingBaseDataBuilderInput? {
        baseDataInput as? StakingBaseDataBuilderInput
    }

    init(
        baseDataInput: SendBaseDataBuilderInput,
        emailDataCollectorBuilder: EmailDataCollectorBuilder,
        emailDataProvider: EmailDataProvider
    ) {
        self.baseDataInput = baseDataInput
        self.emailDataCollectorBuilder = emailDataCollectorBuilder
        self.emailDataProvider = emailDataProvider
    }
}

// MARK: - SendMailDataBuilder

extension CommonSendMailDataBuilder: SendMailDataBuilder {
    // MARK: - Send transaction methods

    func makeMailData(transaction: BSDKTransaction, error: SendTxError) throws -> MailData {
        let emailDataCollector = emailDataCollectorBuilder.makeMailData(
            transaction: transaction,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            error: error
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(approveTransaction: ApproveTransactionData, error: SendTxError) throws -> MailData {
        guard let fee = baseDataInput.bsdkFee else {
            throw SendMailDataBuilderError.notFound("Fee")
        }

        guard let amount = baseDataInput.bsdkAmount else {
            throw SendMailDataBuilderError.notFound("Amount")
        }

        let emailDataCollector = emailDataCollectorBuilder.makeMailData(
            approveTransaction: approveTransaction,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            amount: amount,
            fee: fee,
            error: error
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(expressTransaction: ExpressTransactionData, error: SendTxError) throws -> MailData {
        guard let amount = baseDataInput.bsdkAmount else {
            throw SendMailDataBuilderError.notFound("Amount")
        }

        guard let fee = baseDataInput.bsdkFee else {
            throw SendMailDataBuilderError.notFound("Fee")
        }

        let emailDataCollector = emailDataCollectorBuilder.makeMailData(
            expressTransaction: expressTransaction,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            amount: amount,
            fee: fee,
            error: error
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
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

        let emailDataCollector = emailDataCollectorBuilder.makeMailData(
            stakingActionType: stakingDataInput.stakingActionType,
            target: target,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            amount: amount,
            fee: fee,
            error: error
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }

    func makeMailData(action: StakingTransactionAction, error: SendTxError) throws -> MailData {
        guard let stakingDataInput = stakingDataInput else {
            throw SendMailDataBuilderError.notFound("Staking data input")
        }

        guard let target = stakingDataInput.target else {
            throw SendMailDataBuilderError.notFound("Staking target")
        }

        let emailDataCollector = emailDataCollectorBuilder.makeMailData(
            action: action,
            stakingActionType: stakingDataInput.stakingActionType,
            target: target,
            isFeeIncluded: baseDataInput.isFeeIncluded,
            error: error
        )

        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient

        return (dataCollector: emailDataCollector, recipient: recipient)
    }
}
