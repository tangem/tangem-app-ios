//
//  TransactionDetailsFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
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
    private static let balanceFormatter = BalanceFormatter()
    private static let balanceConverter = BalanceConverter()

    static func reduce(
        transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: TransactionDetailsContext
    ) -> (header: TransactionDetailsHeaderViewData, content: TransactionDetailsViewModel.Content) {
        (
            header(for: transaction, record: record, context: context),
            content(for: transaction, record: record, context: context)
        )
    }

    private static func content(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: TransactionDetailsContext
    ) -> TransactionDetailsViewModel.Content {
        switch record?.expressExtraInfo {
        case .exchange(let info):
            return .swap(swapContent(info, record: record, context: context))
        case .onramp(let info):
            return .onramp(onrampContent(info, context: context))
        case nil:
            return onChainContent(for: transaction, record: record, context: context)
        }
    }

    // MARK: - On-chain (no Express extra)

    private static func onChainContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: TransactionDetailsContext
    ) -> TransactionDetailsViewModel.Content {
        switch transaction.transactionType {
        case .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate,
             .yieldSend, .yieldTopup, .yieldWithdraw, .yieldWithdrawCoin:
            return .yield(yieldContent(for: transaction, record: record, context: context))

        case .stake, .unstake, .vote, .withdraw, .claimRewards, .restake:
            return .generic(genericOperationContent(for: transaction, record: record, context: context, counterpartyLabel: Localization.stakingValidator))

        case .approve:
            return .generic(genericOperationContent(for: transaction, record: record, context: context, counterpartyLabel: Localization.commonAddress))

        // [REDACTED_TODO_COMMENT]
        case .gaslessTransactionFee, .operation, .unknownOperation:
            return .generic(genericOperationContent(for: transaction, record: record, context: context, counterpartyLabel: nil))

        case .transfer, .gaslessTransfer, .swap, .tangemPay:
            return .generic(sendReceiveContent(for: transaction, record: record, context: context))
        }
    }

    private static func tokensBlock(for transaction: TransactionViewModel, context: TransactionDetailsContext) -> TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            tokenIconInfo: context.tokenIconInfo,
            amountText: transaction.amount.amount
        )
    }

    private static func genericOperationContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: TransactionDetailsContext,
        counterpartyLabel: String?
    ) -> TransactionDetailsGenericOperationViewData {
        .init(
            tokens: tokensBlock(for: transaction, context: context),
            // On-chain operations don't get a live status banner (that's an Express-only transition)
            statusBanner: nil,
            // and the "for sending X" block
            principalAmount: nil,
            counterparty: counterpartyLabel.flatMap { counterparty(for: transaction, label: $0) },
            info: networkFeeInfo(from: record),
            action: nil
        )
    }

    private static func yieldContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: TransactionDetailsContext
    ) -> TransactionDetailsYieldViewData {
        .init(
            tokens: TransactionDetailsYieldTokensViewData(
                accountIcon: context.receiverAccountIcon,
                tokenIconInfo: context.tokenIconInfo,
                amountText: transaction.amount.amount,
                statusTitle: yieldStatusTitle(for: transaction.transactionType)
            ),
            statusBanner: nil,
            info: networkFeeInfo(from: record),
            action: nil
        )
    }

    private static func yieldStatusTitle(for type: TransactionViewModel.TransactionType) -> String? {
        switch type {
        case .yieldWithdraw, .yieldWithdrawCoin:
            return Localization.yieldModuleTransactionReturned
        case .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate, .yieldSend, .yieldTopup:
            return Localization.yieldModuleTransactionSupplied
        case .stake, .unstake, .vote, .withdraw, .claimRewards, .restake,
             .approve, .gaslessTransactionFee, .operation, .unknownOperation,
             .transfer, .gaslessTransfer, .swap, .tangemPay:
            return nil
        }
    }

    // MARK: - Swap

    private static func swapContent(
        _ info: ExchangeTransactionInfo,
        record: TransactionRecord?,
        context: TransactionDetailsContext
    ) -> TransactionDetailsSwapViewData {
        let exchange = info.transaction
        let fromToken = info.cryptoCurrencies[exchange.from.currency]
        let toToken = info.cryptoCurrencies[exchange.to.currency]
        let sourceAmount = exchange.from.normalizedAmount
        let destinationAmount = exchange.to.normalizedAmount

        return TransactionDetailsSwapViewData(
            stage: TransactionOperationStatusMapper.stage(for: exchange.status),
            source: leg(amount: sourceAmount, token: fromToken),
            destination: leg(amount: destinationAmount, token: toToken),
            isDestinationEstimated: exchange.rateType == .float,
            statusBanner: swapStatusBanner(exchange.status),
            provider: provider(info.provider, fallbackId: exchange.providerId, externalURL: exchange.externalTx?.url, openURL: context.openURL),
            rate: swapRate(fromAmount: sourceAmount, fromToken: fromToken, toAmount: destinationAmount, toToken: toToken),
            networkFee: networkFee(from: record),
            action: action(for: exchange.status, externalURL: exchange.externalTx?.url, openURL: context.openURL)
        )
    }

    private static func leg(amount: Decimal, token: TokenItem?) -> TransactionDetailsSwapViewData.Leg {
        .init(
            amount: balanceFormatter.formatDecimal(amount),
            symbol: token?.currencySymbol,
            tokenIconInfo: token.map { TokenIconInfoBuilder().build(from: $0, isCustom: false) }
        )
    }

    private static func swapStatusBanner(_ status: ExpressTransactionStatus) -> TransactionDetailsStatusBannerViewData? {
        switch status {
        case .preview, .created, .exchangeTxSent, .waiting:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusReceivingActive)
        case .waitingTxHash:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusWaitingTxHash)
        case .confirming:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusConfirmingActive)
        case .exchanging:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusExchangingActive)
        case .sending:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusSendingActive)
        case .verifying:
            return .init(kind: .attention, title: Localization.expressExchangeStatusVerifying, subtitle: Localization.expressExchangeNotificationVerificationText)
        case .paused:
            return .init(kind: .attention, title: Localization.expressExchangeStatusPaused)
        case .refunded:
            return .init(kind: .warning, title: Localization.expressExchangeStatusRefunded)
        case .failed, .txFailed:
            return .init(kind: .warning, title: Localization.expressExchangeStatusFailed, subtitle: Localization.expressExchangeNotificationFailedText)
        case .expired:
            return .init(kind: .warning, title: Localization.expressExchangeStatusFailed)
        case .finished:
            return .init(kind: .success, title: Localization.expressExchangeStatusExchanged)
        case .unknown:
            return nil
        }
    }

    // MARK: - Onramp

    private static func onrampContent(
        _ info: OnrampTransactionInfo,
        context: TransactionDetailsContext
    ) -> TransactionDetailsOnrampViewData {
        let onramp = info.onrampTransaction
        let receivedAmount = onramp.to.normalizedAmount

        let paid = TransactionDetailsOnrampViewData.PaidLeg(
            amount: balanceFormatter.formatDecimal(onramp.from.amount),
            symbol: onramp.from.currencyCode,
            fiatPrice: nil,
            flagIconURL: info.fiatCurrency?.identity.image ?? IconURLBuilder().fiatIconURL(currencyCode: onramp.from.currencyCode),
            isFlagLoading: info.fiatCurrency == nil
        )

        let destination: TransactionDetailsActor = context.receiverAccountIcon
            .map { .account(name: context.receiverName, icon: $0) }
            ?? .wallet(name: context.receiverName)

        let received = TransactionDetailsOnrampViewData.ReceivedLeg(
            destination: destination,
            amount: balanceFormatter.formatDecimal(receivedAmount),
            symbol: context.tokenSymbol,
            fiatPrice: fiatText(amount: receivedAmount, currencyId: context.tokenCurrencyId),
            tokenIconInfo: context.tokenIconInfo
        )

        return TransactionDetailsOnrampViewData(
            stage: TransactionOperationStatusMapper.stage(for: onramp.status),
            paid: paid,
            received: received,
            isReceivedEstimated: onramp.to.actualAmount == nil,
            statusBanner: onrampStatusBanner(onramp.status),
            provider: provider(info.provider, fallbackId: onramp.providerId, externalURL: onramp.externalTx?.url, openURL: context.openURL),
            rate: fiatRate(cryptoAmount: receivedAmount, cryptoSymbol: context.tokenSymbol, fiatAmount: onramp.from.amount, fiatSymbol: onramp.from.currencyCode),
            action: action(for: onramp.status, externalURL: onramp.externalTx?.url, openURL: context.openURL)
        )
    }

    private static func onrampStatusBanner(_ status: OnrampTransactionStatus) -> TransactionDetailsStatusBannerViewData? {
        switch status {
        case .created, .waitingForPayment:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusReceivingActive)
        case .paymentProcessing:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusConfirmingActive)
        case .paid:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusBuyingActive)
        case .sending:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusSendingActive)
        case .refunding:
            return .init(kind: .inProgress, title: Localization.expressExchangeStatusRefunding)
        case .verifying:
            return .init(kind: .attention, title: Localization.expressExchangeStatusVerifying, subtitle: Localization.expressExchangeNotificationVerificationText)
        case .paused:
            return .init(kind: .attention, title: Localization.expressExchangeStatusPaused)
        case .refunded:
            return .init(kind: .warning, title: Localization.expressExchangeStatusRefunded)
        case .failed:
            return .init(kind: .warning, title: Localization.expressExchangeStatusFailed, subtitle: Localization.expressExchangeNotificationFailedText)
        case .expired:
            return .init(kind: .warning, title: Localization.expressExchangeStatusFailed)
        case .finished:
            return .init(kind: .success, title: Localization.expressExchangeStatusBought)
        case .unknown:
            return nil
        }
    }

    // MARK: - Send / Receive (on-chain, no Express extra)

    private static func sendReceiveContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: TransactionDetailsContext
    ) -> TransactionDetailsGenericOperationViewData {
        let label = transaction.isOutgoing ? Localization.sendRecipient : Localization.commonFrom

        return .init(
            tokens: tokensBlock(for: transaction, context: context),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: counterparty(for: transaction, label: label),
            info: transaction.isOutgoing ? networkFeeInfo(from: record) : nil,
            action: nil
        )
    }

    // MARK: - Shared building blocks

    private static func provider(
        _ provider: ExpressProvider?,
        fallbackId: ExpressProvider.Id,
        externalURL: URL?,
        openURL: @escaping (URL) -> Void
    ) -> TransactionDetailsProviderInfo {
        let onTap: (() -> Void)? = externalURL.map { url in
            { openURL(url) }
        }

        return TransactionDetailsProviderInfo(
            name: provider?.name ?? fallbackId,
            onTap: onTap
        )
    }

    private static func action(
        for swapStatus: ExpressTransactionStatus,
        externalURL: URL?,
        openURL: @escaping (URL) -> Void
    ) -> TransactionDetailsActionButtonViewData? {
        switch swapStatus {
        case .verifying:
            return externalAction(title: Localization.commonGoToVerification, externalURL: externalURL, openURL: openURL)
        case .paused:
            return externalAction(title: Localization.commonGoToProvider, externalURL: externalURL, openURL: openURL)
        case .unknown, .preview, .created, .exchangeTxSent, .waiting, .waitingTxHash,
             .confirming, .exchanging, .sending, .finished, .failed, .txFailed, .refunded, .expired:
            return nil
        }
    }

    private static func action(
        for onrampStatus: OnrampTransactionStatus,
        externalURL: URL?,
        openURL: @escaping (URL) -> Void
    ) -> TransactionDetailsActionButtonViewData? {
        switch onrampStatus {
        case .verifying:
            return externalAction(title: Localization.commonGoToVerification, externalURL: externalURL, openURL: openURL)
        case .paused, .waitingForPayment:
            return externalAction(title: Localization.commonGoToProvider, externalURL: externalURL, openURL: openURL)
        case .unknown, .created, .paymentProcessing, .paid, .sending, .refunding, .finished, .failed, .expired, .refunded:
            return nil
        }
    }

    private static func externalAction(
        title: String,
        externalURL: URL?,
        openURL: @escaping (URL) -> Void
    ) -> TransactionDetailsActionButtonViewData? {
        guard let externalURL else {
            return nil
        }

        return .init(title: title, icon: DesignSystem.Icons.ArrowTopRight.regular20, handler: { openURL(externalURL) })
    }

    private static func swapRate(fromAmount: Decimal, fromToken: TokenItem?, toAmount: Decimal, toToken: TokenItem?) -> String? {
        guard let fromToken, let toToken, fromAmount > 0, toAmount > 0 else {
            return nil
        }

        let baseSymbol: String
        let quoteSymbol: String
        let rate: Decimal

        // [REDACTED_TODO_COMMENT]
        switch SwapRateDisplaySideResolver.resolve(from: fromToken, to: toToken) {
        case .fromIsBase:
            baseSymbol = fromToken.currencySymbol
            quoteSymbol = toToken.currencySymbol
            rate = toAmount / fromAmount
        case .toIsBase:
            baseSymbol = toToken.currencySymbol
            quoteSymbol = fromToken.currencySymbol
            rate = fromAmount / toAmount
        }

        let base = balanceFormatter.formatCryptoBalance(1, currencyCode: baseSymbol)
        let quote = balanceFormatter.formatCryptoBalance(rate, currencyCode: quoteSymbol)
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

    private static func networkFee(from record: TransactionRecord?) -> String? {
        guard let amount = record?.fee.amount else {
            return nil
        }

        return "\(balanceFormatter.formatDecimal(amount.value)) \(amount.currencySymbol)"
    }

    private static func networkFeeInfo(from record: TransactionRecord?) -> TransactionDetailsInfoSectionViewData? {
        guard let fee = networkFee(from: record) else {
            return nil
        }

        return .init(rows: [.init(id: "networkFee", title: Localization.commonNetworkFeeTitle, content: .text(fee))])
    }

    // MARK: - Header

    private static func header(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: TransactionDetailsContext
    ) -> TransactionDetailsHeaderViewData {
        let status = headerStatus(for: record, fallback: transaction.status)
        let title = headerTitle(for: transaction, record: record, status: status)

        var menuActions: [TransactionDetailsHeaderViewData.MenuAction] = [
            copyTransactionIdAction(for: transaction, record: record),
        ]

        // A synthetic id isn't a real on-chain hash, so it can't be explored.
        if let hash = record?.hash, !ExpressSyntheticTxHelper.isSyntheticIdentifier(hash), let url = context.exploreTransactionURL(for: hash) {
            menuActions.append(.init(
                id: "explore",
                title: Localization.commonExplore,
                icon: Assets.Glyphs.explore,
                handler: { context.openURL(url) }
            ))
        }

        // Share is available for swap/onramp (the text is built from the Express `extraInfo`).
        if let shareText = shareText(for: record, context: context) {
            menuActions.append(.init(
                id: "share",
                title: Localization.commonShare,
                icon: Assets.share,
                handler: { context.share(shareText) }
            ))
        }

        return TransactionDetailsHeaderViewData(
            title: title,
            date: transaction.subtitleText,
            operationIcon: TransactionViewIconViewData(type: transaction.transactionType, status: status, isOutgoing: transaction.isOutgoing),
            menuActions: menuActions,
            onClose: context.onClose
        )
    }

    private static func headerTitle(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        status: TransactionViewModel.Status
    ) -> String {
        switch record?.expressExtraInfo {
        case .exchange:
            return swapTitle(status: status)
        case .onramp:
            return onrampTitle(status: status)
        case nil:
            return TransactionDisplayModel.title(
                transactionType: transaction.transactionType,
                status: status,
                isOutgoing: transaction.isOutgoing,
                isFromYieldContract: transaction.isFromYieldContract,
                legacyName: transaction.name,
                subtitleOwner: transaction.subtitleOwner
            )
        }
    }

    private static func copyTransactionIdAction(
        for transaction: TransactionViewModel,
        record: TransactionRecord?
    ) -> TransactionDetailsHeaderViewData.MenuAction {
        let value: String
        switch record?.expressExtraInfo {
        case .exchange(let info):
            value = info.transaction.txId
        case .onramp(let info):
            value = info.onrampTransaction.txId
        case nil:
            value = transaction.hash
        }

        return .init(
            id: "transactionID",
            title: Localization.commonTransactionId,
            icon: Assets.Glyphs.copy,
            handler: { copy(value, toast: Localization.expressTransactionIdCopied) }
        )
    }

    private static func swapTitle(status: TransactionViewModel.Status) -> String {
        switch status {
        case .failed:
            return Localization.commonActionFailed(Localization.commonSwapping)
        case .inProgress:
            return Localization.commonSwapping
        case .confirmed, .undefined:
            return Localization.commonSwapped
        }
    }

    private static func onrampTitle(status: TransactionViewModel.Status) -> String {
        switch status {
        case .failed:
            return Localization.commonActionFailed(Localization.txHistoryOnrampTopUp)
        case .inProgress:
            return Localization.txHistoryOnrampTopUp
        case .confirmed, .undefined:
            return Localization.txHistoryOnrampToppedUp
        }
    }

    private static func headerStatus(for record: TransactionRecord?, fallback: TransactionViewModel.Status) -> TransactionViewModel.Status {
        guard let record else {
            return fallback
        }

        return TransactionOperationStatusMapper.viewStatus(for: record)
    }

    // MARK: - Counterparty (send / receive)

    private static func counterparty(for transaction: TransactionViewModel, label: String) -> TransactionDetailsAddressViewData? {
        switch transaction.subtitleOwner {
        case .accountInCurrentWallet(let name, let icon):
            return .init(label: label, actor: .account(name: name, icon: icon))

        case .accountInOtherWallet(let accountName, let accountIcon, let walletName):
            return .init(label: label, actor: .accountInWallet(accountName: accountName, accountIcon: accountIcon, walletName: walletName))

        case .wallet(let name):
            return .init(label: label, actor: .wallet(name: name))

        case .unresolved(let short, let fullAddress, let blockiesImage):
            return .init(
                label: label,
                actor: .address(short: short, blockiesImage: .init(image: blockiesImage)),
                onCopy: { copy(fullAddress, toast: Localization.walletNotificationAddressCopied) }
            )

        case .none:
            guard let address = counterpartyAddress(for: transaction) else {
                return nil
            }

            return .init(
                label: label,
                actor: .address(
                    short: AddressFormatter(address: address).truncated(),
                    blockiesImage: AddressIconProvider.makeBlockiesIconViewData(address: address)
                ),
                onCopy: { copy(address, toast: Localization.walletNotificationAddressCopied) }
            )
        }
    }

    private static func counterpartyAddress(for transaction: TransactionViewModel) -> String? {
        switch transaction.interactionAddress {
        case .user(let address), .contract(let address):
            return address
        case .multiple(let addresses):
            return addresses.first
        case .staking(let validator):
            return validator
        case .custom:
            return nil
        }
    }

    // MARK: - Share

    private static func shareText(for record: TransactionRecord?, context: TransactionDetailsContext) -> String? {
        switch record?.expressExtraInfo {
        case .exchange(let info):
            return swapShareText(info)
        case .onramp(let info):
            return onrampShareText(info, context: context)
        case nil:
            // On-chain transactions have no Express deal to assemble — share the block-explorer link instead.
            guard let hash = record?.hash, let url = context.exploreTransactionURL(for: hash) else {
                return nil
            }

            return url.absoluteString
        }
    }

    private static func swapShareText(_ info: ExchangeTransactionInfo) -> String {
        let exchange = info.transaction
        let from = amountWithSymbol(exchange.from.normalizedAmount, info.cryptoCurrencies[exchange.from.currency]?.currencySymbol)
        let to = amountWithSymbol(exchange.to.normalizedAmount, info.cryptoCurrencies[exchange.to.currency]?.currencySymbol)

        var lines = ["tangem", ""]
        lines.append("\(Localization.commonSend) \(from)")
        if let fromAddress = exchange.fromAddress {
            lines.append("\(Localization.commonFrom): \(fromAddress)")
        }
        lines.append("")
        lines.append("\(Localization.commonReceive) \(to)")
        lines.append("\(Localization.commonTo): \(exchange.payOut.address)")
        lines.append("")
        lines.append(providerLine(info.provider, fallbackId: exchange.providerId))
        lines.append(Localization.expressTransactionId(exchange.txId))

        return lines.joined(separator: "\n")
    }

    private static func onrampShareText(_ info: OnrampTransactionInfo, context: TransactionDetailsContext) -> String {
        let onramp = info.onrampTransaction
        let to = amountWithSymbol(onramp.to.normalizedAmount, context.tokenSymbol)

        var lines = ["tangem", ""]
        lines.append("\(Localization.commonBuy) \(to)")
        lines.append("\(Localization.commonTo): \(onramp.payOut.address)")
        lines.append("")
        lines.append(providerLine(info.provider, fallbackId: onramp.providerId))
        lines.append(Localization.expressTransactionId(onramp.txId))

        return lines.joined(separator: "\n")
    }

    private static func providerLine(_ provider: ExpressProvider?, fallbackId: ExpressProvider.Id) -> String {
        let name = provider?.name ?? fallbackId
        let type = provider?.type.rawValue.uppercased()
        let info = [name, type].compactMap { $0 }.joined(separator: " ")
        return Localization.expressByProviderPlaceholder(info)
    }

    private static func amountWithSymbol(_ amount: Decimal?, _ symbol: String?) -> String {
        let formattedAmount = amount.map { balanceFormatter.formatDecimal($0) }
        return [formattedAmount, symbol].compactMap { $0 }.joined(separator: " ")
    }

    // MARK: - Side effects

    private static func copy(_ value: String, toast text: String) {
        UIPasteboard.general.string = value
        Toast(view: SuccessToast(text: text)).present(layout: .top(padding: 14), type: .temporary())
    }
}

// MARK: - Express amount normalization

private extension ExpressHistoryAsset {
    /// Final delivered amount when known, otherwise the expected one — the value to show.
    var normalizedAmount: Decimal { actualAmount ?? amount }
}

private extension OnrampHistoryCryptoAsset {
    /// Final delivered amount when known, otherwise the expected one — the value to show.
    var normalizedAmount: Decimal? { actualAmount ?? amount }
}
