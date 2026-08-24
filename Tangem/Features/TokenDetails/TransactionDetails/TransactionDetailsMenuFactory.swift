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
import TangemLocalization

enum TransactionDetailsMenuFactory {
    private static let balanceFormatter = BalanceFormatter()

    static func menuActions(
        for record: TransactionRecord,
        context: TransactionDetailsContext,
        addContactHelper: TransactionDetailsAddContactHelper
    ) -> [TransactionDetailsHeaderViewData.MenuAction] {
        var actions: [TransactionDetailsHeaderViewData.MenuAction] = []

        if isShareAvailable(for: record) {
            actions.append(.init(
                id: "share",
                title: Localization.commonShare,
                icon: Assets.share,
                action: .share
            ))
        }

        actions.append(copyTransactionIdAction(for: record))

        if let url = exploreURL(for: record, context: context) {
            actions.append(.init(
                id: "explore",
                title: Localization.commonExplore,
                icon: Assets.Glyphs.explore,
                action: .openURL(url)
            ))
        }

        if let addressToSave = addContactHelper.addressToSave(for: record) {
            actions.append(.init(
                id: "addContact",
                title: Localization.addressBookAddContact,
                icon: DesignSystem.Icons.UserPlus.regular24,
                action: .addContact(address: addressToSave)
            ))
        }

        #if INTERNAL || DEBUG
        actions.append(.init(
            id: "debug",
            title: "Debug",
            icon: Assets.Glyphs.docNew,
            action: .debug
        ))
        #endif

        return actions
    }

    // MARK: - Transaction id

    private static func copyTransactionIdAction(for record: TransactionRecord) -> TransactionDetailsHeaderViewData.MenuAction {
        .init(
            id: "transactionID",
            title: Localization.commonTransactionId,
            icon: Assets.Glyphs.copy,
            action: .copy(
                value: transactionId(for: record),
                toast: Localization.expressTransactionIdCopied
            )
        )
    }

    private static func transactionId(for record: TransactionRecord) -> String {
        guard let expressExtraInfo = record.expressExtraInfo else {
            return record.hash
        }

        return expressExtraInfo.txId
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
            providerInfo: providerInfo(info.provider, fallbackId: exchange.providerId),
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
        let to = amountWithSymbol(onramp.to.normalizedAmount, context.tokenSymbol)

        return ExpressShareTextBuilder.build(
            operation: .onramp(buy: to, to: onramp.payOut.address),
            providerInfo: providerInfo(info.provider, fallbackId: onramp.providerId),
            transactionId: transactionId,
            onChainHash: onChainHash
        )
    }

    private static func providerInfo(_ provider: ExpressProvider?, fallbackId: ExpressProvider.Id) -> String {
        let name = provider?.name ?? fallbackId
        let type = provider?.type.rawValue.uppercased()
        return [name, type].compactMap { $0 }.joined(separator: " ")
    }

    private static func amountWithSymbol(_ amount: Decimal?, _ symbol: String?) -> String {
        let formattedAmount = amount.map { balanceFormatter.formatDecimal($0) }
        return [formattedAmount, symbol].compactMap { $0 }.joined(separator: " ")
    }
}
