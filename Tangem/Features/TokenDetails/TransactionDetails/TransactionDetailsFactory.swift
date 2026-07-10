//
//  TransactionDetailsFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import BlockchainSdk
import TangemExpress
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

/// Central assembler of the transaction details sheet. Maps a `TransactionRecord` of any operation
/// into a `TransactionDetailsViewModel` (the single container) by building the header and the matching
/// per-operation content
struct TransactionDetailsFactory {
    private let balanceFormatter = BalanceFormatter()
    private let balanceConverter = BalanceConverter()

    struct Context {
        let tokenIconInfo: TokenIconInfo
        let tokenSymbol: String
        let tokenCurrencyId: String?
        let receiverName: String
        let receiverAccountIcon: AccountIconView.ViewData?
        let openExplorer: (() -> Void)?
        let openURL: (URL) -> Void
        let share: (String) -> Void
        let onClose: () -> Void
    }

    func makeViewModel(
        transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context,
        recordUpdates: AnyPublisher<TransactionRecord, Never>
    ) -> TransactionDetailsViewModel {
        let rebuild: (TransactionRecord) -> (header: TransactionDetailsHeaderViewData, content: TransactionDetailsViewModel.Content) = { record in
            (
                header(for: transaction, record: record, context: context),
                content(for: transaction, record: record, context: context)
            )
        }

        return TransactionDetailsViewModel(
            header: header(for: transaction, record: record, context: context),
            content: content(for: transaction, record: record, context: context),
            recordUpdates: recordUpdates,
            rebuild: rebuild
        )
    }

    private func content(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
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

    private func onChainContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
    ) -> TransactionDetailsViewModel.Content {
        switch transaction.transactionType {
        case .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate,
             .yieldSend, .yieldTopup, .yieldWithdraw, .yieldWithdrawCoin:
            return .yield(yieldContent(for: transaction, record: record, context: context))

        case .stake, .unstake, .vote, .withdraw, .claimRewards, .restake:
            return .single(stakingContent(for: transaction, record: record, context: context))

        case .approve:
            return .single(approveContent(for: transaction, record: record, context: context))

        case .gaslessTransactionFee:
            return .single(feeContent(for: transaction, record: record, context: context))

        case .operation, .unknownOperation:
            return .single(otherContent(for: transaction, record: record, context: context))

        case .transfer, .gaslessTransfer, .swap, .tangemPay:
            return .single(sendReceiveContent(for: transaction, record: record, context: context))
        }
    }

    private func tokensBlock(for transaction: TransactionViewModel, context: Context) -> TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            tokenIconInfo: context.tokenIconInfo,
            amountText: transaction.amount.amount
        )
    }

    private func stakingContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
    ) -> TransactionDetailsSingleOperationViewData {
        .init(
            tokens: tokensBlock(for: transaction, context: context),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: counterparty(for: transaction, label: Localization.stakingValidator),
            info: networkFeeInfo(from: record),
            action: nil
        )
    }

    private func approveContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
    ) -> TransactionDetailsSingleOperationViewData {
        .init(
            tokens: tokensBlock(for: transaction, context: context),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: counterparty(for: transaction, label: Localization.stakingValidator),
            info: networkFeeInfo(from: record),
            action: nil
        )
    }

    private func feeContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
    ) -> TransactionDetailsSingleOperationViewData {
        .init(
            tokens: tokensBlock(for: transaction, context: context),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: nil,
            info: networkFeeInfo(from: record),
            action: nil
        )
    }

    private func otherContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
    ) -> TransactionDetailsSingleOperationViewData {
        .init(
            tokens: tokensBlock(for: transaction, context: context),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: nil,
            info: networkFeeInfo(from: record),
            action: nil
        )
    }

    private func yieldContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
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

    private func yieldStatusTitle(for type: TransactionViewModel.TransactionType) -> String? {
        switch type {
        case .yieldWithdraw, .yieldWithdrawCoin:
            return Localization.yieldModuleTransactionReturned
        case .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit, .yieldReactivate, .yieldSend, .yieldTopup:
            return Localization.yieldModuleTransactionSupplied
        default:
            return nil
        }
    }

    // MARK: - Swap

    private func swapContent(
        _ info: ExchangeTransactionInfo,
        record: TransactionRecord?,
        context: Context
    ) -> SwapTransactionDetailsViewData {
        let exchange = info.transaction
        let source = leg(amount: exchange.from.amount, token: info.cryptoCurrencies[exchange.from.currency])
        let destination = leg(amount: exchange.to.actualAmount ?? exchange.to.amount, token: info.cryptoCurrencies[exchange.to.currency])

        return SwapTransactionDetailsViewData(
            stage: swapStage(exchange.status),
            source: source,
            destination: destination,
            isDestinationEstimated: exchange.rateType == .float,
            statusBanner: swapStatusBanner(exchange.status),
            provider: provider(info.provider, fallbackId: exchange.providerId, externalURL: exchange.externalTx?.url, openURL: context.openURL),
            rate: rateString(fromAmount: exchange.from.amount, fromSymbol: source.symbol, toAmount: exchange.to.actualAmount ?? exchange.to.amount, toSymbol: destination.symbol),
            networkFee: networkFee(from: record),
            action: action(for: exchange.status, externalURL: exchange.externalTx?.url, openURL: context.openURL)
        )
    }

    private func leg(amount: Decimal, token: TokenItem?) -> SwapTransactionDetailsViewData.Leg {
        .init(
            amount: balanceFormatter.formatDecimal(amount),
            symbol: token?.currencySymbol,
            tokenIconInfo: token.map { TokenIconInfoBuilder().build(from: $0, isCustom: false) }
        )
    }

    private func swapStage(_ status: ExpressTransactionStatus) -> TransactionDetailsOperationStage {
        switch status {
        case .finished: .finished
        case .failed, .txFailed, .refunded, .expired: .unsuccessful
        case .unknown, .preview, .created, .exchangeTxSent, .waiting, .waitingTxHash, .confirming, .exchanging, .sending, .verifying, .paused: .inProgress
        }
    }

    private func swapStatusBanner(_ status: ExpressTransactionStatus) -> TransactionDetailsStatusBannerViewData? {
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

    private func onrampContent(
        _ info: OnrampTransactionInfo,
        context: Context
    ) -> OnrampTransactionDetailsViewData {
        let onramp = info.onrampTransaction

        let paid = OnrampTransactionDetailsViewData.PaidLeg(
            amount: balanceFormatter.formatDecimal(onramp.from.amount),
            symbol: onramp.from.currencyCode,
            fiatPrice: nil,
            flagIconURL: info.fiatCurrency?.identity.image ?? IconURLBuilder().fiatIconURL(currencyCode: onramp.from.currencyCode),
            isFlagLoading: info.fiatCurrency == nil
        )
        let receivedAmount = onramp.to.actualAmount ?? onramp.to.amount
        let destination: TransactionDetailsActor = context.receiverAccountIcon
            .map { .account(name: context.receiverName, icon: $0) }
            ?? .wallet(name: context.receiverName)
        let received = OnrampTransactionDetailsViewData.ReceivedLeg(
            destination: destination,
            amount: balanceFormatter.formatDecimal(receivedAmount),
            symbol: context.tokenSymbol,
            fiatPrice: fiatText(amount: receivedAmount, currencyId: context.tokenCurrencyId),
            tokenIconInfo: context.tokenIconInfo
        )

        return OnrampTransactionDetailsViewData(
            stage: onrampStage(onramp.status),
            paid: paid,
            received: received,
            isReceivedEstimated: onramp.to.actualAmount == nil,
            statusBanner: onrampStatusBanner(onramp.status),
            provider: provider(info.provider, fallbackId: onramp.providerId, externalURL: onramp.externalTx?.url, openURL: context.openURL),
            rate: rateString(fromAmount: onramp.from.amount, fromSymbol: onramp.from.currencyCode, toAmount: onramp.to.amount, toSymbol: context.tokenSymbol),
            action: action(for: onramp.status, externalURL: onramp.externalTx?.url, openURL: context.openURL)
        )
    }

    private func onrampStage(_ status: OnrampTransactionStatus) -> TransactionDetailsOperationStage {
        switch status {
        case .finished: .finished
        case .failed, .expired, .refunded: .unsuccessful
        case .unknown, .created, .waitingForPayment, .paymentProcessing, .verifying, .paid, .sending, .refunding, .paused: .inProgress
        }
    }

    private func onrampStatusBanner(_ status: OnrampTransactionStatus) -> TransactionDetailsStatusBannerViewData? {
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

    private func sendReceiveContent(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
    ) -> TransactionDetailsSingleOperationViewData {
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

    private func provider(_ provider: ExpressProvider?, fallbackId: ExpressProvider.Id, externalURL: URL?, openURL: @escaping (URL) -> Void) -> TransactionDetailsProviderInfo {
        TransactionDetailsProviderInfo(
            name: provider?.name ?? fallbackId,
            iconURL: provider?.imageURL,
            onTap: externalURL.map { url in { openURL(url) } }
        )
    }

    private func action(for swapStatus: ExpressTransactionStatus, externalURL: URL?, openURL: @escaping (URL) -> Void) -> TransactionDetailsActionButtonViewData? {
        switch swapStatus {
        case .verifying:
            return externalURL.map { url in .init(title: Localization.commonGoToVerification, icon: Assets.arrowRightUpMini, handler: { openURL(url) }) }
        case .paused:
            return externalURL.map { url in .init(title: Localization.commonGoToProvider, icon: Assets.arrowRightUpMini, handler: { openURL(url) }) }
        default:
            return nil
        }
    }

    private func action(for onrampStatus: OnrampTransactionStatus, externalURL: URL?, openURL: @escaping (URL) -> Void) -> TransactionDetailsActionButtonViewData? {
        switch onrampStatus {
        case .verifying:
            return externalURL.map { url in .init(title: Localization.commonGoToVerification, icon: Assets.arrowRightUpMini, handler: { openURL(url) }) }
        case .paused, .waitingForPayment:
            return externalURL.map { url in .init(title: Localization.commonGoToProvider, icon: Assets.arrowRightUpMini, handler: { openURL(url) }) }
        default:
            return nil
        }
    }

    // [REDACTED_TODO_COMMENT]
    private func rateString(fromAmount: Decimal, fromSymbol: String?, toAmount: Decimal?, toSymbol: String?) -> String? {
        guard let fromSymbol, let toSymbol, let toAmount, toAmount > 0, fromAmount > 0 else { return nil }
        let rate = balanceFormatter.formatDecimal(fromAmount / toAmount)
        return "1 \(toSymbol) ≈ \(rate) \(fromSymbol)"
    }

    private func fiatText(amount: Decimal?, currencyId: String?) -> String? {
        guard let amount, let currencyId, let fiat = balanceConverter.convertToFiat(amount, currencyId: currencyId) else { return nil }
        return balanceFormatter.formatFiatBalance(fiat)
    }

    private func networkFee(from record: TransactionRecord?) -> String? {
        guard let amount = record?.fee.amount else { return nil }
        return "\(balanceFormatter.formatDecimal(amount.value)) \(amount.currencySymbol)"
    }

    private func networkFeeInfo(from record: TransactionRecord?) -> TransactionDetailsInfoSectionViewData? {
        guard let fee = networkFee(from: record) else { return nil }
        return .init(rows: [.init(id: "networkFee", title: Localization.commonNetworkFeeTitle, content: .text(fee))])
    }

    // MARK: - Header

    private func header(
        for transaction: TransactionViewModel,
        record: TransactionRecord?,
        context: Context
    ) -> TransactionDetailsHeaderViewData {
        let status = headerStatus(for: record, fallback: transaction.status)

        let title: String
        switch record?.expressExtraInfo {
        case .exchange:
            title = swapTitle(status: status)
        case .onramp:
            title = onrampTitle(status: status)
        case nil:
            title = TransactionDisplayModel.make(
                transactionType: transaction.transactionType,
                status: status,
                isOutgoing: transaction.isOutgoing,
                isFromYieldContract: transaction.isFromYieldContract,
                legacyName: transaction.name,
                amount: transaction.amount.amount,
                addressDestination: transaction.addressDestination,
                subtitleOwner: transaction.subtitleOwner
            ).title
        }

        var menuActions: [TransactionDetailsHeaderViewData.MenuAction] = [
            .init(
                id: "transactionID",
                title: Localization.commonTransactionId,
                icon: Assets.Glyphs.copy,
                handler: { copy(transaction.hash, toast: Localization.expressTransactionIdCopied) }
            ),
        ]

        if let openExplorer = context.openExplorer {
            menuActions.append(.init(id: "explore", title: Localization.commonExplore, icon: Assets.Glyphs.explore, handler: openExplorer))
        }

        // Share is available for swap/onramp (the text is built from the Express `extraInfo`).
        if let shareText = shareText(for: record, context: context) {
            menuActions.append(.init(id: "share", title: Localization.commonShare, icon: Assets.share, handler: { context.share(shareText) }))
        }

        return TransactionDetailsHeaderViewData(
            title: title,
            date: transaction.subtitleText,
            operationIcon: TransactionViewIconViewData(type: transaction.transactionType, status: status, isOutgoing: transaction.isOutgoing),
            menuActions: menuActions,
            onClose: context.onClose
        )
    }

    private func swapTitle(status: TransactionViewModel.Status) -> String {
        switch status {
        case .failed: Localization.commonActionFailed(Localization.commonSwapping)
        case .inProgress: Localization.commonSwapping
        case .confirmed, .undefined: Localization.commonSwapped
        }
    }

    private func onrampTitle(status: TransactionViewModel.Status) -> String {
        switch status {
        case .failed: Localization.commonActionFailed(Localization.expressExchangeStatusBuying)
        case .inProgress: Localization.expressExchangeStatusBuying
        case .confirmed, .undefined: Localization.expressExchangeStatusBought
        }
    }

    private func headerStatus(for record: TransactionRecord?, fallback: TransactionViewModel.Status) -> TransactionViewModel.Status {
        switch record?.expressExtraInfo {
        case .exchange(let info):
            return status(for: swapStage(info.transaction.status))
        case .onramp(let info):
            return status(for: onrampStage(info.onrampTransaction.status))
        case nil:
            guard let record else { return fallback }
            switch record.status {
            case .confirmed: return .confirmed
            case .failed: return .failed
            case .unconfirmed: return .inProgress
            case .undefined: return .undefined
            }
        }
    }

    private func status(for stage: TransactionDetailsOperationStage) -> TransactionViewModel.Status {
        switch stage {
        case .inProgress: .inProgress
        case .finished: .confirmed
        case .unsuccessful: .failed
        }
    }

    // MARK: - Counterparty (send / receive)

    private func counterparty(for transaction: TransactionViewModel, label: String) -> TransactionDetailsAddressViewData? {
        switch transaction.subtitleOwner {
        case .account(let name, let icon):
            return .init(label: label, actor: .account(name: name, icon: icon))

        case .accountInWallet(let accountName, let accountIcon, let walletName):
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
            guard let address = counterpartyAddress(for: transaction) else { return nil }
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

    private func counterpartyAddress(for transaction: TransactionViewModel) -> String? {
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

    private func shareText(for record: TransactionRecord?, context: Context) -> String? {
        switch record?.expressExtraInfo {
        case .exchange(let info):
            return swapShareText(info)
        case .onramp(let info):
            return onrampShareText(info, context: context)
        case nil:
            return nil
        }
    }

    private func swapShareText(_ info: ExchangeTransactionInfo) -> String {
        let exchange = info.transaction
        let from = amountWithSymbol(exchange.from.amount, info.cryptoCurrencies[exchange.from.currency]?.currencySymbol)
        let to = amountWithSymbol(exchange.to.actualAmount ?? exchange.to.amount, info.cryptoCurrencies[exchange.to.currency]?.currencySymbol)

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
        lines.append(Localization.expressTransactionId(exchange.externalTx?.id ?? exchange.txId))

        return lines.joined(separator: "\n")
    }

    private func onrampShareText(_ info: OnrampTransactionInfo, context: Context) -> String {
        let onramp = info.onrampTransaction
        let to = amountWithSymbol(onramp.to.actualAmount ?? onramp.to.amount, context.tokenSymbol)

        var lines = ["tangem", ""]
        lines.append("\(Localization.commonBuy) \(to)")
        lines.append("\(Localization.commonTo): \(onramp.payOut.address)")
        lines.append("")
        lines.append(providerLine(info.provider, fallbackId: onramp.providerId))
        lines.append(Localization.expressTransactionId(onramp.externalTx?.id ?? onramp.txId))

        return lines.joined(separator: "\n")
    }

    private func providerLine(_ provider: ExpressProvider?, fallbackId: ExpressProvider.Id) -> String {
        let name = provider?.name ?? fallbackId
        let type = provider?.type.rawValue.uppercased()
        let info = [name, type].compactMap { $0 }.joined(separator: " ")
        return Localization.expressByProviderPlaceholder(info)
    }

    private func amountWithSymbol(_ amount: Decimal?, _ symbol: String?) -> String {
        [amount.map { balanceFormatter.formatDecimal($0) }, symbol].compactMap { $0 }.joined(separator: " ")
    }

    // MARK: - Side effects

    private func copy(_ value: String, toast text: String) {
        UIPasteboard.general.string = value
        Toast(view: SuccessToast(text: text)).present(layout: .top(padding: 14), type: .temporary())
    }
}
