//
//  TransactionDetailsPreviewFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

/// Preview data for the transaction details sheet. Lives in `Preview Content` (stripped from release
/// builds), so it needs no `#if DEBUG` and doesn't extend the production view-data types.
@MainActor
enum TransactionDetailsPreviewFactory {
    // MARK: - Send / Receive

    static func sent() -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(
            header: header(title: "Sent", operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: true)),
            content: .sendReceive(TransactionDetailsSendReceiveViewData(
                tokens: .init(tokenIconInfo: icon("Tether"), amountText: "−350.31 USDT", fiatText: "$350.31"),
                statusBanner: nil,
                counterparty: .init(label: "Recipient", actor: .address(short: truncatedAddress, blockiesImage: .init(image: nil)), onCopy: {}),
                info: .init(rows: [.init(id: "fee", title: "Network fee", content: .text("0.00056 ETH"))]),
                action: nil
            ))
        )
    }

    static func received() -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(
            header: header(title: "Received", operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: false)),
            content: .sendReceive(TransactionDetailsSendReceiveViewData(
                tokens: .init(tokenIconInfo: icon("Tether"), amountText: "+350.31 USDT", fiatText: "$350.31"),
                statusBanner: nil,
                counterparty: .init(label: "From address", actor: .address(short: truncatedAddress, blockiesImage: .init(image: nil)), onCopy: {}),
                info: nil,
                action: nil
            ))
        )
    }

    // MARK: - Tokens block

    static func tokensSingle() -> TransactionDetailsTokensViewData {
        .init(tokenIconInfo: icon("Tether", color: .green), amountText: "+350.31 USDT", fiatText: "$350.31")
    }

    static func tokensPair() -> TransactionDetailsTokensViewData {
        .init(
            from: .init(direction: "From", tokenIconInfo: icon("Tether", color: .green), amountText: "− 390 USDT", fiatText: "$391.12"),
            to: .init(direction: "To", tokenIconInfo: icon("Polygon", color: .purple), amountText: "~ 1,800.00 POL", fiatText: "$391.12")
        )
    }
}

// MARK: - Shared builders

private extension TransactionDetailsPreviewFactory {
    static let truncatedAddress = "33Bd321fS...ga21412B"

    static let menuActions: [TransactionDetailsHeaderViewData.MenuAction] = [
        .init(id: "transactionID", title: "Transaction ID", icon: Assets.Glyphs.copy, handler: {}),
        .init(id: "explore", title: "Explore", icon: Assets.Glyphs.explore, handler: {}),
    ]

    static func icon(_ name: String, color: Color? = nil) -> TokenIconInfo {
        TokenIconInfo(name: name, blockchainIconAsset: nil, imageURL: nil, isCustom: false, customTokenColor: color)
    }

    static func header(title: String, operationIcon: TransactionViewIconViewData) -> TransactionDetailsHeaderViewData {
        .init(title: title, date: "Jan 20 2026, 9:24 PM", operationIcon: operationIcon, menuActions: menuActions, onClose: {})
    }
}
