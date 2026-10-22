//
//  TransactionDetailsAnalyticsLogger.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

enum TransactionDetailsProviderNavigationSource: Equatable {
    case status
    case kyc
    case longTime

    var parameterValue: Analytics.ParameterValue {
        switch self {
        case .status: .status
        case .kyc: .kyc
        case .longTime: .longTime
        }
    }
}

/// Analytics of the transaction detail sheet.
final class TransactionDetailsAnalyticsLogger {
    private let tokenItem: TokenItem

    private var state: State?
    private var didLogScreenOpened = false
    private var loggedStatusBanners: Set<Analytics.Event> = []

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    // MARK: - Record updates

    func recordUpdated(_ record: TransactionRecord, transaction: TransactionViewModel) {
        let state = State(record: record, transaction: transaction)
        self.state = state

        if !didLogScreenOpened {
            didLogScreenOpened = true
            logScreenOpened(state)
            logExpressStatusOpened(state)
        }

        logStatusBannerIfNeeded(state)
    }

    // MARK: - User actions

    func logCopyAddress() {
        logAction(.tokenButtonCopyAddress)
    }

    func logCopyTransactionID() {
        logAction(.transactionDetailButtonCopyTransactionID, source: nil)
    }

    func logShare() {
        logAction(.tokenButtonShare)
    }

    func logExplore() {
        logAction(.buttonExplore)
    }

    func logGoToProvider(source: TransactionDetailsProviderNavigationSource) {
        guard let state, let express = state.record.expressExtraInfo else {
            return
        }

        Analytics.log(
            event: express.isOnramp ? .onrampButtonGoToProvider : .tokenButtonGoToProvider,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: express.providerName,
                .place: source.parameterValue.rawValue,
            ]
        )
    }

    func logGoToToken() {
        Analytics.log(.tokenButtonGoToToken)
    }

    // MARK: - Screen opened

    private func logScreenOpened(_ state: State) {
        var params = actionParams(state)
        params[.status] = Self.status(for: state.transaction.status).rawValue
        params[.title] = Self.title(for: state.transaction)

        Analytics.log(event: .transactionDetailScreenOpened, params: params)
    }

    private func logExpressStatusOpened(_ state: State) {
        switch state.record.expressExtraInfo {
        case .exchange(let info):
            Analytics.log(
                event: .tokenSwapStatusScreenOpened,
                params: [
                    .token: tokenItem.currencySymbol,
                    .provider: info.providerName,
                ]
            )
        case .onramp(let info):
            Analytics.log(
                event: .onrampOnrampStatusOpened,
                params: [
                    .token: tokenItem.currencySymbol,
                    .provider: info.providerName,
                    .currency: info.transaction.from.currencyCode,
                ]
            )
        case nil:
            break
        }
    }

    // MARK: - Status banner

    /// The banner the user sees is what gets reported, so the trigger is the navigation source the sheet
    /// resolved for this transaction rather than a second reading of the status here.
    private func logStatusBannerIfNeeded(_ state: State) {
        guard let express = state.record.expressExtraInfo else {
            return
        }

        switch (express, TransactionDetailsFactory.providerNavigationSource(for: express)) {
        case (.onramp(let info), .kyc):
            logStatusBannerShown(.onrampNoticeKYC, provider: info.providerName)

        case (.exchange(let info), .longTime):
            logStatusBannerShown(.tokenNoticeLongTimeTransaction, provider: info.providerName)

        default:
            break
        }
    }

    private func logStatusBannerShown(_ event: Analytics.Event, provider: String) {
        guard loggedStatusBanners.insert(event).inserted else {
            return
        }

        Analytics.log(
            event: event,
            params: [
                .token: tokenItem.currencySymbol,
                .provider: provider,
            ]
        )
    }

    // MARK: - Parameters

    private func logAction(_ event: Analytics.Event, source: Analytics.ParameterValue? = .txHistoryTransactionDetail) {
        guard let state else {
            return
        }

        var params = actionParams(state)
        params[.source] = source?.rawValue

        Analytics.log(event: event, params: params)
    }

    private func actionParams(_ state: State) -> [Analytics.ParameterKey: String] {
        [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .type: Self.type(for: state.transaction).rawValue,
        ]
    }

    private static func status(for status: TransactionViewModel.Status) -> Analytics.ParameterValue {
        switch status {
        case .confirmed: .txHistoryConfirmed
        case .inProgress: .pending
        case .failed: .failed
        case .undefined: .unknown
        }
    }

    private static func type(for transaction: TransactionViewModel) -> Analytics.ParameterValue {
        switch transaction.transactionType {
        case .transfer, .gaslessTransfer, .tangemPay:
            transaction.isOutgoing ? .send : .receive
        case .yieldSend where transaction.isTransferLikeYieldSend:
            transaction.isOutgoing ? .send : .receive
        case .swap:
            .swap
        case .onramp:
            .onramp
        case .approve:
            .transactionSourceApprove
        case .stake, .unstake, .vote, .withdraw, .claimRewards, .restake:
            .transactionSourceStaking
        case .incentiveClaim, .incentiveClaimCoin, .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate,
             .yieldSend, .yieldTopup, .yieldWithdraw, .yieldWithdrawCoin:
            .yieldModuleSourceInfo
        case .gaslessTransactionFee, .networkFee, .operation, .unknownOperation:
            .txHistoryOperation
        }
    }

    private static func title(for transaction: TransactionViewModel) -> String {
        if case .operation(let name) = transaction.transactionType {
            return name
        }

        return titleValue(for: transaction).rawValue
    }

    private static func titleValue(for transaction: TransactionViewModel) -> Analytics.ParameterValue {
        switch transaction.transactionType {
        case .transfer, .gaslessTransfer, .tangemPay:
            transferTitle(for: transaction)
        case .yieldSend where transaction.isTransferLikeYieldSend:
            transferTitle(for: transaction)
        case .swap:
            .swap
        case .onramp:
            .txHistoryTopUp
        case .approve:
            .transactionSourceApprove
        case .stake:
            .stakeActionStake
        case .unstake:
            .stakeActionUnstake
        case .vote:
            .stakeActionVote
        case .withdraw:
            .stakeActionWithdraw
        case .claimRewards:
            .stakeActionClaimRewards
        case .restake:
            .stakeActionRestake
        case .incentiveClaim, .incentiveClaimCoin, .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate,
             .yieldSend, .yieldTopup, .yieldWithdraw, .yieldWithdrawCoin:
            .yieldModuleSourceInfo
        case .gaslessTransactionFee, .networkFee:
            .fee
        case .operation, .unknownOperation:
            .txHistoryOperation
        }
    }

    private static func transferTitle(for transaction: TransactionViewModel) -> Analytics.ParameterValue {
        guard transaction.subtitleOwner?.isOwnWallet != true else {
            return .transfer
        }

        return transaction.isOutgoing ? .sent : .txHistoryReceived
    }
}

// MARK: - Nested types

private extension TransactionDetailsAnalyticsLogger {
    struct State {
        let record: TransactionRecord
        let transaction: TransactionViewModel
    }
}

// MARK: - Express helpers

private extension TransactionHistoryExpressExtraInfo {
    var isOnramp: Bool {
        switch self {
        case .onramp: true
        case .exchange: false
        }
    }

    var providerName: String {
        switch self {
        case .exchange(let info): info.providerName
        case .onramp(let info): info.providerName
        }
    }
}

private extension ExchangeTransactionInfo {
    var providerName: String {
        provider?.name ?? transaction.providerId
    }
}

private extension OnrampTransactionInfo {
    var providerName: String {
        provider?.name ?? transaction.providerId
    }
}

private extension TransactionViewModel {
    var isTransferLikeYieldSend: Bool {
        transactionType.isTransferLikeYieldSend(isOutgoing: isOutgoing, isFromYieldContract: isFromYieldContract)
    }
}
