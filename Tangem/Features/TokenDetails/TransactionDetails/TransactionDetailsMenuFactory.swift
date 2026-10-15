//
//  TransactionDetailsMenuFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemAssets
import TangemFoundation
import TangemLocalization

enum TransactionDetailsMenuFactory {
    private static let balanceFormatter = BalanceFormatter()

    private static let yieldProviderURL = URL(string: "https://aave.com/")!

    static func menuSections(
        for record: TransactionRecord,
        counterpartyAddress: String?,
        transactionType: TransactionViewModel.TransactionType,
        context: TransactionDetailsContext,
        addContactHelper: TransactionDetailsAddContactHelper
    ) -> [TransactionDetailsHeaderViewData.MenuSection] {
        var addressActions: [TransactionDetailsHeaderViewData.MenuAction] = []

        if let counterpartyAddress {
            addressActions.append(copyAddressAction(for: counterpartyAddress))
        }

        if let addressToSave = addContactHelper.addressToSave(for: record) {
            addressActions.append(.init(
                id: "addContact",
                title: Localization.addressBookAddContact,
                icon: DesignSystem.Icons.UserPlus.regular24,
                action: .addContact(address: addressToSave)
            ))
        }

        var transactionActions: [TransactionDetailsHeaderViewData.MenuAction] = []

        if isShareAvailable(for: record) {
            transactionActions.append(.init(
                id: "share",
                title: Localization.commonShare,
                icon: DesignSystem.Icons.ShareIos.regular24,
                action: .share
            ))
        }

        transactionActions.append(copyProviderTransactionIdAction(for: record) ?? copyTransactionIdAction(for: record))

        if let url = exploreURL(for: record, context: context) {
            transactionActions.append(.init(
                id: "explore",
                title: Localization.commonExplore,
                icon: DesignSystem.Icons.Globe.regular24,
                action: .openURL(url, kind: .explorer)
            ))
        }

        if isYieldProviderInteraction(transactionType) {
            transactionActions.append(.init(
                id: "exploreProvider",
                title: Localization.yieldModuleExploreSheetExploreAaveButtonTitle,
                icon: DesignSystem.Icons.Globe.regular24,
                action: .openURL(yieldProviderURL, kind: .yieldProvider)
            ))
        }

        var sections: [TransactionDetailsHeaderViewData.MenuSection] = [
            .init(id: "address", actions: addressActions),
            .init(id: "transaction", actions: transactionActions),
        ]

        #if INTERNAL || DEBUG
        sections.append(.init(id: "debug", actions: [
            .init(
                id: "debug",
                title: "Debug",
                icon: DesignSystem.Icons.Document.regular24,
                action: .debug
            ),
        ]))
        #endif

        return sections.filter { $0.actions.isNotEmpty }
    }

    // MARK: - Address

    static func copyAddressAction(for address: String) -> TransactionDetailsHeaderViewData.MenuAction {
        .init(
            id: "copyAddress",
            title: Localization.commonCopyAddress,
            icon: DesignSystem.Icons.Copy.regular24,
            action: .copy(
                value: address,
                toast: Localization.walletNotificationAddressCopied,
                kind: .address
            )
        )
    }

    // MARK: - Yield provider

    private static func isYieldProviderInteraction(_ transactionType: TransactionViewModel.TransactionType) -> Bool {
        switch transactionType {
        case .yieldDeploy, .yieldEnter, .yieldEnterCoin, .yieldInit,
             .yieldReactivate, .yieldTopup, .yieldWithdraw, .yieldWithdrawCoin:
            return true
        case .incentiveClaim, .incentiveClaimCoin, .yieldSend, .stake, .unstake, .vote, .withdraw, .claimRewards, .restake,
             .approve, .gaslessTransactionFee, .gaslessTransfer, .networkFee, .operation, .unknownOperation,
             .transfer, .swap, .onramp, .tangemPay:
            return false
        }
    }

    // MARK: - Transaction id

    private static func copyTransactionIdAction(for record: TransactionRecord) -> TransactionDetailsHeaderViewData.MenuAction {
        .init(
            id: "transactionID",
            title: Localization.commonTransactionId,
            icon: DesignSystem.Icons.Copy.regular24,
            action: .copy(
                value: transactionId(for: record),
                toast: Localization.expressTransactionIdCopied,
                kind: .transactionID
            )
        )
    }

    private static func transactionId(for record: TransactionRecord) -> String {
        guard let expressExtraInfo = record.expressExtraInfo else {
            return record.hash
        }

        return expressExtraInfo.txId
    }

    private static func copyProviderTransactionIdAction(for record: TransactionRecord) -> TransactionDetailsHeaderViewData.MenuAction? {
        let externalTx: ExternalTxInfo?
        let title: String
        let toast: String

        switch record.expressExtraInfo {
        case .exchange(let info):
            externalTx = info.transaction.externalTx
            title = Localization.expressSwapId
            toast = Localization.expressSwapIdCopied
        case .onramp(let info):
            externalTx = info.transaction.externalTx
            title = Localization.expressOnrampId
            toast = Localization.expressOnrampIdCopied
        case nil:
            return nil
        }

        guard let externalTx else {
            return nil
        }

        return .init(
            id: "providerTransactionID",
            title: title,
            icon: DesignSystem.Icons.Copy.regular24,
            action: .copy(value: externalTx.id, toast: toast, kind: .transactionID)
        )
    }

    private static func onChainHash(for record: TransactionRecord) -> String? {
        ExpressSyntheticTxHelper.isSyntheticIdentifier(record.hash) ? nil : record.hash
    }

    // MARK: - Explore

    private static func exploreURL(for record: TransactionRecord, context: TransactionDetailsContext) -> URL? {
        guard let hash = onChainHash(for: record) else {
            return nil
        }

        return context.exploreTransactionURL(for: hash)
    }

    // MARK: - Share

    private static func isShareAvailable(for record: TransactionRecord) -> Bool {
        record.expressExtraInfo != nil
    }

    static func shareText(for record: TransactionRecord, context: TransactionDetailsContext) -> String? {
        switch record.expressExtraInfo {
        case .exchange(let info):
            return swapShareText(info, transactionId: transactionId(for: record), onChainHash: onChainHash(for: record))
        case .onramp(let info):
            return onrampShareText(info, transactionId: transactionId(for: record), onChainHash: onChainHash(for: record), context: context)
        case nil:
            return nil
        }
    }

    private static func swapShareText(_ info: ExchangeTransactionInfo, transactionId: String, onChainHash: String?) -> String {
        let exchange = info.transaction
        let from = amountWithSymbol(exchange.from.normalizedAmount, info.cryptoCurrencies[exchange.from.currency]?.currencySymbol)
        let to = amountWithSymbol(exchange.to.normalizedAmount, info.cryptoCurrencies[exchange.to.currency]?.currencySymbol)

        return ExpressShareTextBuilder.build(
            operation: .swap(send: from, from: exchange.fromAddress, receive: to, to: exchange.payOut.address),
            providerInfo: providerInfo(info.provider),
            transactionId: transactionId,
            onChainHash: onChainHash
        )
    }

    private static func onrampShareText(
        _ info: OnrampTransactionInfo,
        transactionId: String,
        onChainHash: String?,
        context: TransactionDetailsContext
    ) -> String {
        let onramp = info.transaction
        let send = amountWithSymbol(onramp.from.amount, onramp.from.currencyCode)
        let receive = amountWithSymbol(onramp.to.normalizedAmount, context.tokenSymbol)

        return ExpressShareTextBuilder.build(
            operation: .onramp(send: send, receive: receive, to: onramp.payOut.address),
            providerInfo: providerInfo(info.provider),
            transactionId: transactionId,
            onChainHash: onChainHash
        )
    }

    private static func providerInfo(_ provider: ExpressProvider?) -> String? {
        provider.map { "\($0.name) \($0.type.rawValue.uppercased())" }
    }

    private static func amountWithSymbol(_ amount: Decimal?, _ symbol: String?) -> String {
        let formattedAmount = amount.map { balanceFormatter.formatDecimal($0) }
        return [formattedAmount, symbol].compactMap { $0 }.joined(separator: " ")
    }
}
