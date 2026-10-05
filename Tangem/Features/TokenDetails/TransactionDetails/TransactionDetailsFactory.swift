//
//  TransactionDetailsFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

/// Stateless reducer from a `TransactionRecord` to the sheet's header + per-operation content. Stateless
/// because `reduce` runs on every record update; the formatters are shared statics (their `NumberFormatter`s
/// are cached in `BalanceNumberFormatterCache`).
enum TransactionDetailsFactory {
    struct RefundTarget {
        let tokenItem: TokenItem
        let address: String
    }

    private static let balanceFormatter = BalanceFormatter()
    private static let balanceConverter = BalanceConverter()
    private static let headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func reduce(
        transaction: TransactionViewModel,
        record: TransactionRecord,
        cryptoAmount: Decimal,
        context: TransactionDetailsContext,
        addContactHelper: TransactionDetailsAddContactHelper
    ) -> (header: TransactionDetailsHeaderViewData, content: TransactionDetailsViewModel.Content) {
        let content = content(for: transaction, record: record, cryptoAmount: cryptoAmount, context: context)

        return (
            header(
                for: transaction,
                record: record,
                context: context,
                addContactHelper: addContactHelper,
                counterpartyAddress: copyableCounterpartyAddress(in: content)
            ),
            content
        )
    }

    private static func copyableCounterpartyAddress(in content: TransactionDetailsViewModel.Content) -> String? {
        guard
            case .generic(let data) = content,
            case .copy(let address, _, _) = data.counterparty?.copyAction
        else {
            return nil
        }

        return address
    }

    private static func content(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        cryptoAmount: Decimal,
        context: TransactionDetailsContext
    ) -> TransactionDetailsViewModel.Content {
        switch record.expressExtraInfo {
        case .exchange(let info):
            return .swap(swapContent(info, transaction: transaction, record: record, context: context))
        case .onramp(let info):
            return .onramp(onrampContent(info, context: context))
        case nil:
            return onChainContent(for: transaction, record: record, cryptoAmount: cryptoAmount, context: context)
        }
    }

    // MARK: - On-chain (no Express extra)

    private static func onChainContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        cryptoAmount: Decimal,
        context: TransactionDetailsContext
    ) -> TransactionDetailsViewModel.Content {
        switch transaction.transactionType {
        case .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate,
             .yieldSend, .yieldTopup, .yieldWithdraw, .yieldWithdrawCoin:
            // Only the two operations that move the balance in or out of the protocol get the paired layout;
            // the rest are a plain single-asset amount, which the generic block already renders.
            guard let stage = yieldStage(for: transaction.transactionType) else {
                return .generic(genericOperationContent(
                    for: transaction,
                    record: record,
                    context: context,
                    counterpartyLabel: nil,
                    ignoringDirection: true
                ))
            }

            return .yield(yieldContent(for: transaction, stage: stage, record: record, context: context))

        case .approve where isDecodedApprove(record):
            return .generic(approveContent(for: transaction, record: record, context: context))

        case .approve:
            return .generic(genericOperationContent(
                for: transaction,
                record: record,
                context: context,
                counterpartyLabel: Localization.commonAddress,
                ignoringDirection: false
            ))

        case .stake, .unstake, .vote, .withdraw, .claimRewards, .restake:
            return .generic(stakingOperationContent(for: transaction, record: record, context: context))

        case .gaslessTransactionFee, .networkFee:
            return .generic(feeContent(for: transaction, record: record, cryptoAmount: cryptoAmount, context: context))

        case .operation, .unknownOperation:
            return .generic(genericOperationContent(
                for: transaction,
                record: record,
                context: context,
                counterpartyLabel: resolvedStakingTargetLabel(for: transaction),
                ignoringDirection: false
            ))

        case .transfer, .gaslessTransfer, .swap, .onramp, .tangemPay:
            return .generic(sendReceiveContent(for: transaction, record: record, context: context))
        }
    }

    private static func stakingTarget(for transaction: TransactionViewModel) -> TransactionViewModel.StakingTarget? {
        guard case .staking(.some(let target)) = transaction.interactionAddress else {
            return nil
        }

        return target
    }

    /// Operations that only sometimes turn out to be staking — a bare contract call, a gasless fee — claim the
    /// validator only once its address resolves to a name; unresolved, it is just the contract they touched.
    /// Staking operations proper don't go through here: they name the validator in their info section instead.
    private static func resolvedStakingTarget(for transaction: TransactionViewModel) -> TransactionViewModel.StakingTarget? {
        guard let target = stakingTarget(for: transaction), target.isResolved else {
            return nil
        }

        return target
    }

    private static func resolvedStakingTargetLabel(for transaction: TransactionViewModel) -> String? {
        resolvedStakingTarget(for: transaction) == nil ? nil : Localization.stakingValidator
    }

    private static func isDecodedApprove(_ record: TransactionRecord) -> Bool {
        if case .approve = record.type {
            return true
        }

        return false
    }

    private static func tokensBlock(
        for transaction: TransactionViewModel,
        isFailed: Bool,
        caption: String?,
        fiatText: String?,
        icon: TransactionDetailsTokensViewData.Single.Icon
    ) -> TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            icon: icon,
            caption: caption,
            amountText: transaction.amount.amountWithCurrencyCode,
            fiatText: fiatText,
            isAmountStrikethrough: isFailed
        )
    }

    private static func isFailed(record: TransactionRecord) -> Bool {
        TransactionOperationStatusMapper.viewStatus(for: record) == .failed
    }

    private static func genericOperationContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        context: TransactionDetailsContext,
        counterpartyLabel: String?,
        ignoringDirection: Bool
    ) -> TransactionDetailsGenericOperationViewData {
        .init(
            tokens: tokensBlock(
                for: transaction,
                isFailed: isFailed(record: record),
                caption: nil,
                fiatText: nil,
                icon: .token(context.tokenIconInfo)
            ),
            // On-chain operations don't get a live status banner (that's an Express-only transition)
            statusBanner: nil,
            // and the "for sending X" block
            principalAmount: nil,
            counterparty: counterpartyLabel.flatMap { counterparty(for: transaction, label: $0) },
            info: networkFeeInfo(from: record, ignoringDirection: ignoringDirection),
            action: nil
        )
    }

    private static func stakingOperationContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        context: TransactionDetailsContext
    ) -> TransactionDetailsGenericOperationViewData {
        .init(
            tokens: tokensBlock(
                for: transaction,
                isFailed: isFailed(record: record),
                caption: nil,
                fiatText: nil,
                icon: .token(context.tokenIconInfo)
            ),
            statusBanner: stakingStatusBanner(for: transaction, record: record),
            principalAmount: nil,
            counterparty: nil,
            info: stakingInfo(for: transaction, record: record),
            action: nil
        )
    }

    private static func approveContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        context: TransactionDetailsContext
    ) -> TransactionDetailsGenericOperationViewData {
        let isFailed = isFailed(record: record)

        return .init(
            tokens: tokensBlock(
                for: transaction,
                isFailed: isFailed,
                caption: Localization.transactionHistoryApprovedAmount,
                fiatText: nil,
                icon: approvedTokenIcon(for: record, context: context)
            ),
            statusBanner: isFailed ? nil : highRiskBanner(for: record),
            principalAmount: nil,
            counterparty: nil,
            info: networkFeeInfo(from: record, ignoringDirection: false),
            action: nil
        )
    }

    private static func stakingStatusBanner(
        for transaction: TransactionViewModel,
        record: TransactionRecord
    ) -> TransactionDetailsStatusBannerViewData? {
        guard isFailed(record: record) else {
            return nil
        }

        return .init(
            kind: .failed,
            title: transaction.display.title.fullText,
            subtitle: Localization.commonSomethingWentWrong
        )
    }

    private static func stakingInfo(
        for transaction: TransactionViewModel,
        record: TransactionRecord
    ) -> TransactionDetailsInfoSectionViewData? {
        var rows: [TransactionDetailsInfoSectionViewData.Row] = []

        if let target = stakingTarget(for: transaction) {
            rows.append(TransactionDetailsInfoSectionViewData.Row(id: "validator", title: Localization.stakingValidator, content: validatorContent(for: target)))
        }

        if let fee = networkFee(from: record, ignoringDirection: false) {
            rows.append(.init(id: "networkFee", title: Localization.commonNetworkFeeTitle, content: .sensitiveText(fee)))
        }

        return rows.isEmpty ? nil : .init(rows: rows)
    }

    private static func validatorContent(for target: TransactionViewModel.StakingTarget) -> TransactionDetailsInfoSectionViewData.Row.Content {
        target.isResolved ? .text(target.name) : .address(target.address)
    }

    private static func approvedTokenIcon(
        for record: TransactionRecord,
        context: TransactionDetailsContext
    ) -> TransactionDetailsTokensViewData.Single.Icon {
        guard let tokenContract = record.approvedTokenContract,
              let resolved = context.tokenIconInfo(forContract: tokenContract)
        else {
            return .unresolved(network: context.networkIconAsset)
        }

        return .token(resolved)
    }

    private static func highRiskBanner(for record: TransactionRecord) -> TransactionDetailsStatusBannerViewData? {
        guard case .approve(let approve) = record.type, approve.allowance == .unlimited else {
            return nil
        }

        return .init(
            kind: .attention,
            title: Localization.transactionHistoryApproveHighRiskTitle,
            subtitle: Localization.transactionHistoryApproveHighRiskSubtitle
        )
    }

    // MARK: - Fee

    private static func feeContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        cryptoAmount: Decimal,
        context: TransactionDetailsContext
    ) -> TransactionDetailsGenericOperationViewData {
        .init(
            tokens: tokensBlock(
                for: transaction,
                isFailed: isFailed(record: record),
                caption: nil,
                fiatText: fiatText(amount: cryptoAmount, currencyId: context.tokenCurrencyId),
                icon: .token(context.tokenIconInfo)
            ),
            statusBanner: nil,
            principalAmount: sentTokens(for: transaction),
            counterparty: nil,
            info: nil,
            action: nil
        )
    }

    private static func sentTokens(for transaction: TransactionViewModel) -> TransactionDetailsPrincipalAmountViewData? {
        guard case .networkFee(_, .some(let sent)) = transaction.transactionType else {
            return nil
        }

        return .init(
            icon: DesignSystem.Icons.ArrowUp.regular24,
            label: Localization.commonSend,
            amount: sent.amount,
            tokenIconInfo: sent.iconInfo
        )
    }

    // MARK: - Yield

    private static func yieldContent(
        for transaction: TransactionViewModel,
        stage: YieldStage,
        record: TransactionRecord,
        context: TransactionDetailsContext
    ) -> TransactionDetailsYieldViewData {
        .init(
            tokens: TransactionDetailsYieldTokensViewData(
                provider: stage.provider,
                tokenIconInfo: context.tokenIconInfo,
                amountText: transaction.amount.amountWithCurrencyCode,
                caption: stage.caption
            ),
            statusBanner: nil,
            info: networkFeeInfo(from: record, ignoringDirection: true),
            action: nil
        )
    }

    private static func yieldStage(for type: TransactionViewModel.TransactionType) -> YieldStage? {
        switch type {
        case .yieldEnter, .yieldEnterCoin:
            return YieldStage(provider: .leading(Assets.YieldModule.yieldModuleAaveLogo), caption: Localization.yieldModuleTransactionSupplied)
        case .yieldWithdraw, .yieldWithdrawCoin:
            return YieldStage(provider: .trailing(Assets.YieldModule.yieldModuleAaveLogo), caption: Localization.yieldModuleTransactionReturned)
        case .yieldDeploy, .yieldInit, .yieldReactivate, .yieldSend, .yieldTopup,
             .stake, .unstake, .vote, .withdraw, .claimRewards, .restake,
             .approve, .gaslessTransactionFee, .networkFee, .operation, .unknownOperation,
             .transfer, .gaslessTransfer, .swap, .onramp, .tangemPay:
            return nil
        }
    }

    // MARK: - Swap

    private static func swapContent(
        _ info: ExchangeTransactionInfo,
        transaction: TransactionViewModel,
        record: TransactionRecord,
        context: TransactionDetailsContext
    ) -> TransactionDetailsSwapViewData {
        let exchange = info.transaction
        let fromToken = info.cryptoCurrencies[exchange.from.currency]
        let toToken = info.cryptoCurrencies[exchange.to.currency]
        let sourceAmount = exchange.from.normalizedAmount
        let destinationAmount = exchange.to.normalizedAmount
        let isLongRunning = isLongRunningSwap(exchange)
        let refund = refundedIn(exchange: exchange, info: info)

        let parties = swapParties(for: transaction, context: context)

        return TransactionDetailsSwapViewData(
            stage: TransactionOperationStatusMapper.stage(for: exchange.status),
            source: leg(amount: sourceAmount, token: fromToken, actor: parties?.source),
            destination: leg(amount: destinationAmount, token: toToken, actor: parties?.destination),
            isDestinationEstimated: exchange.rateType == .float,
            statusBanner: refund?.banner ?? swapStatusBanner(exchange.status, isLongRunning: isLongRunning),
            provider: provider(info.provider, fallbackId: exchange.providerId, externalURL: exchange.externalTx?.url),
            rate: swapRate(fromAmount: sourceAmount, fromToken: fromToken, toAmount: destinationAmount, toToken: toToken),
            networkFee: networkFee(from: record, ignoringDirection: false),
            action: refund?.action ?? action(for: exchange.status, isLongRunning: isLongRunning, externalURL: exchange.externalTx?.url),
            ratingTransaction: ratingTransaction(for: exchange, providerName: info.provider?.name)
        )
    }

    private static func ratingTransaction(for exchange: ExchangeTransaction, providerName: String?) -> TransactionDetailsSwapViewData.RatingTransaction? {
        guard RatingModel.Transaction.isRateable(exchange.status) else { return nil }

        return TransactionDetailsSwapViewData.RatingTransaction(
            transactionId: exchange.txId,
            providerId: exchange.providerId,
            providerName: providerName,
            txUrl: exchange.externalTx?.url?.absoluteString
        )
    }

    /// The "Refunded in [TOKEN]" plaque for a refunded deal whose refund token resolves, plus an optional "Go to token" action
    private static func refundedIn(
        exchange: ExchangeTransaction,
        info: ExchangeTransactionInfo
    ) -> (banner: TransactionDetailsStatusBannerViewData, action: TransactionDetailsActionButtonViewData?)? {
        guard let target = refundTarget(exchange: exchange, info: info) else {
            return nil
        }

        let symbol = target.tokenItem.currencySymbol

        let banner = TransactionDetailsStatusBannerViewData(
            kind: .refundInfo,
            title: Localization.expressExchangeNotificationRefundedInTitle(symbol),
            subtitle: Localization.expressExchangeNotificationRefundedInText(symbol, target.tokenItem.networkName)
        )
        // "Go to token" adds the refund token to the portfolio if needed, then opens it.
        let action = TransactionDetailsActionButtonViewData(
            title: Localization.commonGoToToken,
            icon: DesignSystem.Icons.ChevronRight.regular20,
            style: .secondary,
            action: .openRefundToken
        )
        return (banner, action)
    }

    static func refundTarget(for record: TransactionRecord) -> RefundTarget? {
        guard case .exchange(let info) = record.expressExtraInfo else {
            return nil
        }

        return refundTarget(exchange: info.transaction, info: info)
    }

    private static func refundTarget(exchange: ExchangeTransaction, info: ExchangeTransactionInfo) -> RefundTarget? {
        guard
            exchange.status == .refunded,
            let refund = exchange.refund,
            let refundCurrency = refund.currency,
            let refundToken = info.cryptoCurrencies[refundCurrency]
        else {
            return nil
        }

        return RefundTarget(tokenItem: refundToken, address: refund.address)
    }

    /// "Long transaction time": an active swap stuck for more than 15 minutes since `createdAt`
    static func isLongRunningSwap(_ exchange: ExchangeTransaction) -> Bool {
        let threshold: TimeInterval = 15 * 60
        let elapsed = Date().timeIntervalSince(exchange.createdAt)
        guard elapsed > threshold else {
            return false
        }

        switch exchange.status {
        case .confirming, .exchanging, .sending:
            return true
        case .waiting, .waitingTxHash, .exchangeTxSent:
            return exchange.payIn.hash != nil
        case .preview, .created, .unknown, .verifying, .paused,
             .finished, .failed, .txFailed, .refunded, .expired:
            return false
        }
    }

    static func providerNavigationSource(for info: TransactionHistoryExpressExtraInfo) -> TransactionDetailsProviderNavigationSource? {
        switch info {
        case .exchange(let info):
            providerNavigationSource(for: info.transaction.status, isLongRunning: isLongRunningSwap(info.transaction))
        case .onramp(let info):
            providerNavigationSource(for: info.transaction.status)
        }
    }

    private static func providerNavigationSource(
        for swapStatus: ExpressTransactionStatus,
        isLongRunning: Bool
    ) -> TransactionDetailsProviderNavigationSource? {
        if isLongRunning {
            return .longTime
        }

        switch swapStatus {
        case .verifying:
            return .kyc
        case .paused:
            return .status
        case .unknown, .preview, .created, .exchangeTxSent, .waiting, .waitingTxHash,
             .confirming, .exchanging, .sending, .finished, .failed, .txFailed, .refunded, .expired:
            return nil
        }
    }

    private static func providerNavigationSource(for onrampStatus: OnrampTransactionStatus) -> TransactionDetailsProviderNavigationSource? {
        switch onrampStatus {
        case .verifying:
            .kyc
        case .paused, .waitingForPayment:
            .status
        case .unknown, .created, .paymentProcessing, .paid, .sending, .refunding, .finished, .failed, .expired, .refunded:
            nil
        }
    }

    private static func leg(amount: Decimal, token: TokenItem?, actor: TransactionDetailsActor?) -> TransactionDetailsSwapViewData.Leg {
        .init(
            amount: balanceFormatter.formatDecimal(amount),
            symbol: token?.currencySymbol,
            tokenIconInfo: token.map { TokenIconInfoBuilder().build(from: $0, isCustom: false) },
            actor: actor
        )
    }

    private static func swapParties(
        for transaction: TransactionViewModel,
        context: TransactionDetailsContext
    ) -> (source: TransactionDetailsActor, destination: TransactionDetailsActor)? {
        guard
            case .express(let subtitle) = transaction.display.subtitle,
            let counterpartyOwner = subtitle.counterparty
        else {
            return nil
        }

        let holder = holderActor(context: context)
        let counterparty = actor(for: counterpartyOwner)

        if transaction.isOutgoing {
            return (source: holder, destination: counterparty)
        }

        return (source: counterparty, destination: holder)
    }

    private static func holderActor(context: TransactionDetailsContext) -> TransactionDetailsActor {
        context.receiverAccountIcon
            .map { .account(name: context.receiverName, icon: $0) }
            ?? .wallet(name: context.receiverName)
    }

    private static func actor(for owner: TransactionViewModel.SubtitleOwner) -> TransactionDetailsActor {
        switch owner {
        case .accountInCurrentWallet(let name, let icon):
            return .account(name: name, icon: icon)
        case .accountInOtherWallet(let accountName, let accountIcon):
            return .account(name: accountName, icon: accountIcon)
        case .wallet(let name, _, _):
            return .wallet(name: name)
        case .contact(let name, let icon, _):
            return .contact(name: name, icon)
        case .unresolved(_, let fullAddress, let blockiesImage):
            return .address(fullAddress, blockiesImage: AddressBlockiesIconViewData(image: blockiesImage))
        }
    }

    private static func swapStatusBanner(_ status: ExpressTransactionStatus, isLongRunning: Bool) -> TransactionDetailsStatusBannerViewData? {
        if isLongRunning {
            return .init(
                kind: .attention,
                title: Localization.expressExchangeNotificationLongTransactionTimeTitle,
                subtitle: Localization.expressExchangeNotificationLongTransactionTimeText
            )
        }

        switch status {
        case .preview, .unknown:
            return nil
        case .created, .exchangeTxSent, .waitingTxHash, .exchanging, .sending:
            return .init(kind: .inProgress, title: Localization.commonInProgress)
        case .waiting:
            return .init(kind: .inProgress, title: Localization.txHistoryOnrampStatusAwaitingFunds)
        case .confirming:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusConfirmed)
        case .verifying:
            return .init(kind: .attention, title: Localization.expressExchangeStatusVerifying, subtitle: Localization.expressExchangeNotificationVerificationText)
        case .paused:
            return .init(kind: .attention, title: Localization.txHistoryOnrampStatusPaused, subtitle: Localization.txHistoryTransactionPausedNotificationTitle)
        case .refunded:
            return .init(kind: .refunded, title: Localization.txHistoryOnrampStatusRefunded)
        case .failed, .txFailed:
            return .init(kind: .failed, title: Localization.txHistoryOnrampStatusFailed, subtitle: Localization.expressExchangeNotificationFailedText)
        case .expired:
            return .init(kind: .expired, title: Localization.txHistoryDetailsStatusExpired)
        case .finished:
            return .init(kind: .success, title: Localization.expressExchangeStatusExchanged)
        }
    }

    // MARK: - Onramp

    private static func onrampContent(
        _ info: OnrampTransactionInfo,
        context: TransactionDetailsContext
    ) -> TransactionDetailsOnrampViewData {
        let onramp = info.transaction
        let receivedAmount = onramp.to.normalizedAmount

        let paid = TransactionDetailsOnrampViewData.PaidLeg(
            amount: balanceFormatter.formatDecimal(onramp.from.amount),
            symbol: onramp.from.currencyCode,
            flagIconURL: info.fiatCurrency?.identity.image ?? IconURLBuilder().fiatIconURL(currencyCode: onramp.from.currencyCode),
            isFlagLoading: info.fiatCurrency == nil
        )

        let received = TransactionDetailsOnrampViewData.ReceivedLeg(
            destination: holderActor(context: context),
            amount: receivedAmount.map { balanceFormatter.formatDecimal($0) },
            symbol: context.tokenSymbol,
            tokenIconInfo: context.tokenIconInfo
        )

        return TransactionDetailsOnrampViewData(
            stage: TransactionOperationStatusMapper.stage(for: onramp.status),
            paid: paid,
            received: received,
            statusBanner: onrampStatusBanner(onramp.status),
            provider: provider(info.provider, fallbackId: onramp.providerId, externalURL: onramp.externalTx?.url),
            rate: fiatRate(cryptoAmount: receivedAmount, cryptoSymbol: context.tokenSymbol, fiatAmount: onramp.from.amount, fiatSymbol: onramp.from.currencyCode),
            action: action(for: onramp.status, externalURL: onramp.externalTx?.url)
        )
    }

    private static func onrampStatusBanner(_ status: OnrampTransactionStatus) -> TransactionDetailsStatusBannerViewData? {
        switch status {
        case .unknown:
            return nil
        case .created, .paymentProcessing, .paid, .sending:
            return .init(kind: .inProgress, title: Localization.commonInProgress)
        case .waitingForPayment:
            return .init(kind: .inProgress, title: Localization.txHistoryOnrampStatusAwaitingFunds)
        case .refunding:
            return .init(kind: .refunding, title: Localization.txHistoryOnrampStatusRefunding)
        case .verifying:
            return .init(kind: .attention, title: Localization.expressExchangeStatusVerifying, subtitle: Localization.expressExchangeNotificationVerificationText)
        case .paused:
            return .init(kind: .attention, title: Localization.txHistoryOnrampStatusPaused, subtitle: Localization.txHistoryTransactionPausedNotificationTitle)
        case .refunded:
            return .init(kind: .refunded, title: Localization.txHistoryOnrampStatusRefunded)
        case .failed:
            return .init(kind: .failed, title: Localization.txHistoryOnrampStatusFailed, subtitle: Localization.expressExchangeNotificationFailedText)
        case .expired:
            return .init(kind: .expired, title: Localization.txHistoryDetailsStatusExpired)
        case .finished:
            return .init(kind: .success, title: Localization.expressExchangeStatusBought)
        }
    }

    // MARK: - Send / Receive (on-chain, no Express extra)

    private static func sendReceiveContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        context: TransactionDetailsContext
    ) -> TransactionDetailsGenericOperationViewData {
        return .init(
            tokens: tokensBlock(
                for: transaction,
                isFailed: isFailed(record: record),
                caption: nil,
                fiatText: nil,
                icon: .token(context.tokenIconInfo)
            ),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: counterparty(for: transaction, label: counterpartyLabel(for: transaction)),
            info: networkFeeInfo(from: record, ignoringDirection: false),
            action: nil
        )
    }

    /// Incoming rows label the counterparty by kind (wallet / account / address); outgoing stays "Recipient".
    private static func counterpartyLabel(for transaction: TransactionViewModel) -> String {
        guard !transaction.isOutgoing else {
            return Localization.sendRecipient
        }

        switch transaction.subtitleOwner {
        case .wallet:
            return Localization.commonFromWallet
        case .accountInCurrentWallet, .accountInOtherWallet:
            return Localization.commonFromAccount
        case .contact:
            return Localization.addressBookContact
        case .unresolved, .none:
            return Localization.commonFromAddress
        }
    }

    // MARK: - Shared building blocks

    private static func provider(
        _ provider: ExpressProvider?,
        fallbackId: ExpressProvider.Id,
        externalURL: URL?
    ) -> TransactionDetailsProviderInfo {
        TransactionDetailsProviderInfo(
            name: provider?.name ?? fallbackId,
            type: providerTypeTitle(provider?.type),
            action: externalURL.map { .openURL($0, kind: .provider(source: .status)) }
        )
    }

    /// CEX / DEX label for the provider row. Onramp (and unknown) providers have no meaningful type to surface here.
    private static func providerTypeTitle(_ type: ExpressProviderType?) -> String? {
        guard let type else {
            return nil
        }

        switch type {
        case .dex, .cex, .dexBridge:
            return type.title
        case .onramp, .unknown:
            return nil
        }
    }

    private static func action(
        for swapStatus: ExpressTransactionStatus,
        isLongRunning: Bool,
        externalURL: URL?
    ) -> TransactionDetailsActionButtonViewData? {
        externalAction(source: providerNavigationSource(for: swapStatus, isLongRunning: isLongRunning), externalURL: externalURL)
    }

    private static func action(
        for onrampStatus: OnrampTransactionStatus,
        externalURL: URL?
    ) -> TransactionDetailsActionButtonViewData? {
        externalAction(source: providerNavigationSource(for: onrampStatus), externalURL: externalURL)
    }

    private static func externalAction(
        source: TransactionDetailsProviderNavigationSource?,
        externalURL: URL?
    ) -> TransactionDetailsActionButtonViewData? {
        guard let source, let externalURL else {
            return nil
        }

        return .init(
            title: source.actionTitle,
            icon: DesignSystem.Icons.ArrowTopRight.regular20,
            style: .default,
            action: .openURL(externalURL, kind: .provider(source: source))
        )
    }

    private static func swapRate(fromAmount: Decimal, fromToken: TokenItem?, toAmount: Decimal, toToken: TokenItem?) -> String? {
        guard let fromToken, let toToken, fromAmount > 0, toAmount > 0 else {
            return nil
        }

        let baseSymbol: String
        let quoteToken: TokenItem
        let rate: Decimal

        switch SwapRateDisplaySideResolver.resolve(from: fromToken, to: toToken) {
        case .fromIsBase:
            baseSymbol = fromToken.currencySymbol
            quoteToken = toToken
            rate = toAmount / fromAmount
        case .toIsBase:
            baseSymbol = toToken.currencySymbol
            quoteToken = fromToken
            rate = fromAmount / toAmount
        }

        let base = balanceFormatter.formatCryptoBalance(1, currencyCode: baseSymbol)
        let quote = balanceFormatter.formatCryptoBalance(
            rate,
            currencyCode: quoteToken.currencySymbol,
            formattingOptions: .cryptoRateFormattingOptions(decimalCount: quoteToken.decimalCount)
        )
        return "\(base) \(AppConstants.approximatelyEqualSign) \(quote)"
    }

    private static func fiatRate(cryptoAmount: Decimal?, cryptoSymbol: String, fiatAmount: Decimal, fiatSymbol: String) -> String? {
        guard let cryptoAmount, cryptoAmount > 0, fiatAmount > 0 else {
            return nil
        }

        let rate = balanceFormatter.formatDecimal(fiatAmount / cryptoAmount)
        return "1 \(cryptoSymbol) \(AppConstants.approximatelyEqualSign) \(rate) \(fiatSymbol)"
    }

    private static func fiatText(amount: Decimal?, currencyId: String?) -> String? {
        guard let amount, let currencyId, let fiat = balanceConverter.convertToFiat(amount, currencyId: currencyId) else {
            return nil
        }

        return balanceFormatter.formatFiatBalance(fiat)
    }

    /// The fee is shown only for outgoing operations, unless the caller knows the wallet paid it even though
    /// the record reads as incoming. Synthetic Express records never show one either way.
    private static func networkFee(from record: TransactionRecord, ignoringDirection: Bool) -> String? {
        guard
            record.isOutgoing || ignoringDirection,
            // Hide network fee for synthetic Express records
            !ExpressSyntheticTxHelper.isSyntheticIdentifier(record.hash)
        else {
            return nil
        }

        let amount = record.fee.amount
        return "\(balanceFormatter.formatDecimal(amount.value)) \(amount.currencySymbol)"
    }

    private static func networkFeeInfo(
        from record: TransactionRecord,
        ignoringDirection: Bool
    ) -> TransactionDetailsInfoSectionViewData? {
        guard let fee = networkFee(from: record, ignoringDirection: ignoringDirection) else {
            return nil
        }

        return .init(rows: [.init(id: "networkFee", title: Localization.commonNetworkFeeTitle, content: .sensitiveText(fee))])
    }

    // MARK: - Header

    private static func header(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        context: TransactionDetailsContext,
        addContactHelper: TransactionDetailsAddContactHelper,
        counterpartyAddress: String?
    ) -> TransactionDetailsHeaderViewData {
        let status = TransactionOperationStatusMapper.viewStatus(for: record)
        let title = headerTitle(for: transaction, record: record, status: status)

        let dateText: String
        if let date = record.date {
            dateText = headerDateFormatter.string(from: date)
        } else {
            dateText = transaction.subtitleText
        }

        return TransactionDetailsHeaderViewData(
            title: title.text,
            titleStyle: title.style,
            date: dateText,
            subtitleStyle: .secondary,
            operationIcon: TransactionViewIconViewData(
                type: transaction.transactionType,
                status: status,
                isOutgoing: transaction.isOutgoing,
                isFromYieldContract: transaction.isFromYieldContract
            ),
            iconGlyph: headerIconGlyph(for: record),
            menuSections: TransactionDetailsMenuFactory.menuSections(
                for: record,
                counterpartyAddress: counterpartyAddress,
                transactionType: transaction.transactionType,
                context: context,
                addContactHelper: addContactHelper
            )
        )
    }

    private static func headerIconGlyph(for record: TransactionRecord) -> ImageType? {
        switch record.expressExtraInfo {
        case .exchange: DesignSystem.Icons.ArrowSwapHorizontal.regular20
        case .onramp: DesignSystem.Icons.Card.regular20
        case nil: nil
        }
    }

    private static func headerTitle(
        for transaction: TransactionViewModel,
        record: TransactionRecord,
        status: TransactionViewModel.Status
    ) -> (text: String, style: TransactionDetailsHeaderViewData.TitleStyle) {
        switch record.expressExtraInfo {
        case .exchange(let info):
            return swapTitle(status: info.transaction.status)
        case .onramp(let info):
            return onrampTitle(status: info.transaction.status)
        case nil:
            let text = TransactionDisplayModel.title(
                transactionType: transaction.transactionType,
                status: status,
                isOutgoing: transaction.isOutgoing,
                isFromYieldContract: transaction.isFromYieldContract,
                legacyName: transaction.name,
                subtitleOwner: transaction.subtitleOwner
            )
            return (text.fullText, onChainTitleStyle(for: status))
        }
    }

    private static func onChainTitleStyle(for status: TransactionViewModel.Status) -> TransactionDetailsHeaderViewData.TitleStyle {
        switch status {
        case .inProgress: .active
        case .failed, .undefined: .failed
        case .confirmed: .neutral
        }
    }

    private static func swapTitle(status: ExpressTransactionStatus) -> (text: String, style: TransactionDetailsHeaderViewData.TitleStyle) {
        switch status {
        case .preview, .created, .exchangeTxSent, .waiting, .waitingTxHash,
             .confirming, .exchanging, .sending, .unknown:
            return (Localization.commonSwapping, .active)
        case .verifying, .paused:
            return (Localization.commonSwapping, .attention)
        case .finished:
            return (Localization.commonSwapped, .neutral)
        case .failed, .txFailed, .refunded:
            return (Localization.transactionHistoryStatusSwapFailed, .failed)
        case .expired:
            return (Localization.transactionHistoryStatusSwapFailed, .expired)
        }
    }

    private static func onrampTitle(status: OnrampTransactionStatus) -> (text: String, style: TransactionDetailsHeaderViewData.TitleStyle) {
        switch status {
        case .created, .waitingForPayment, .paymentProcessing, .paid, .sending, .refunding, .unknown,
             .verifying, .paused:
            return (Localization.transactionHistoryStatusToppingUp, .active)
        case .finished:
            return (Localization.txHistoryOnrampToppedUp, .neutral)
        case .failed, .refunded, .expired:
            return (Localization.transactionHistoryStatusTopUpFailed, .failed)
        }
    }

    // MARK: - Counterparty (send / receive)

    private static func counterparty(for transaction: TransactionViewModel, label: String) -> TransactionDetailsAddressViewData? {
        switch transaction.subtitleOwner {
        case .accountInCurrentWallet(let name, let icon):
            return .init(label: label, actor: .account(name: name, icon: icon), copyAction: nil, walletImageProvider: nil)

        case .accountInOtherWallet(let accountName, let accountIcon):
            return .init(label: label, actor: .account(name: accountName, icon: accountIcon), copyAction: nil, walletImageProvider: nil)

        case .wallet(let name, let imageProvider, _):
            return .init(label: label, actor: .wallet(name: name), copyAction: nil, walletImageProvider: imageProvider)

        case .contact(let name, let icon, let fullAddress):
            return .init(
                label: label,
                actor: .contact(name: name, icon),
                copyAction: copyAddressAction(for: fullAddress),
                walletImageProvider: nil
            )

        case .unresolved(_, let fullAddress, let blockiesImage):
            if let stakingCounterparty = stakingCounterparty(for: transaction, label: label) {
                return stakingCounterparty
            }

            return .init(
                label: label,
                actor: .address(fullAddress, blockiesImage: AddressBlockiesIconViewData(image: blockiesImage)),
                copyAction: copyAddressAction(for: fullAddress),
                walletImageProvider: nil
            )

        case .none:
            if let stakingCounterparty = stakingCounterparty(for: transaction, label: label) {
                return stakingCounterparty
            }

            guard let address = counterpartyAddress(for: transaction) else {
                return nil
            }

            return .init(
                label: label,
                actor: .address(
                    address,
                    blockiesImage: AddressIconProvider.makeBlockiesIconViewData(address: address)
                ),
                copyAction: copyAddressAction(for: address),
                walletImageProvider: nil
            )
        }
    }

    private static func stakingCounterparty(
        for transaction: TransactionViewModel,
        label: String
    ) -> TransactionDetailsAddressViewData? {
        guard let target = resolvedStakingTarget(for: transaction) else {
            return nil
        }

        return .init(
            label: label,
            actor: .validator(
                name: target.name,
                blockiesImage: AddressIconProvider.makeBlockiesIconViewData(address: target.address)
            ),
            copyAction: copyAddressAction(for: target.address),
            walletImageProvider: nil
        )
    }

    private static func copyAddressAction(for address: String) -> TransactionDetailsViewModel.ViewAction {
        .copy(value: address, toast: Localization.walletNotificationAddressCopied, kind: .address)
    }

    private static func counterpartyAddress(for transaction: TransactionViewModel) -> String? {
        switch transaction.interactionAddress {
        case .user(let address), .contract(let address):
            return address
        case .multiple(let addresses):
            return addresses.first
        case .staking(let target):
            return target?.address
        case .custom:
            return nil
        }
    }
}

// MARK: - Yield

private extension TransactionDetailsFactory {
    struct YieldStage {
        let provider: TransactionDetailsYieldTokensViewData.Provider
        let caption: String
    }
}

// MARK: - Provider link

private extension TransactionDetailsProviderNavigationSource {
    var actionTitle: String {
        switch self {
        case .kyc: Localization.commonGoToVerification
        case .status, .longTime: Localization.commonGoToProvider
        }
    }
}
