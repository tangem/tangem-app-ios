//
//  TransactionDetailsPreviewSupport.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import SwiftUI
import TangemAssets
import TangemUI

extension [TransactionDetailsHeaderViewData.MenuAction] {
    static var transactionDetailsPreview: [TransactionDetailsHeaderViewData.MenuAction] {
        [
            .init(id: "transactionID", title: "Transaction ID", icon: Assets.Glyphs.copy, handler: {}),
            .init(id: "explore", title: "Explore", icon: Assets.Glyphs.explore, handler: {}),
        ]
    }
}

extension TokenIconInfo {
    static func transactionDetailsPreview(name: String, color: Color? = nil) -> TokenIconInfo {
        TokenIconInfo(
            name: name,
            blockchainIconAsset: nil,
            imageURL: nil,
            isCustom: false,
            customTokenColor: color
        )
    }
}

private let previewTruncatedAddress = "33Bd321fS...ga21412B"

// MARK: - Send / Receive

extension SendTransactionDetailsViewModel {
    static func preview() -> SendTransactionDetailsViewModel {
        SendTransactionDetailsViewModel(
            tokens: .init(tokenIconInfo: .transactionDetailsPreview(name: "Tether"), amountText: "−350.31 USDT", fiatText: "$350.31"),
            recipient: .init(label: "Recipient", actor: .address(short: previewTruncatedAddress, blockiesImage: nil), onCopy: {}),
            info: .init(rows: [.init(id: "fee", title: "Network fee", content: .text("0.00056 ETH"))])
        )
    }

    static func previewFailed() -> SendTransactionDetailsViewModel {
        SendTransactionDetailsViewModel(
            tokens: .init(tokenIconInfo: .transactionDetailsPreview(name: "Tether"), amountText: "−350.31 USDT", fiatText: "$350.31"),
            statusBanner: .init(kind: .warning, title: "Failed", subtitle: "The transaction was not sent"),
            recipient: .init(label: "Recipient", actor: .address(short: previewTruncatedAddress, blockiesImage: nil), onCopy: {}),
            info: .init(rows: [.init(id: "fee", title: "Network fee", content: .text("0.00056 ETH"))])
        )
    }
}

extension ReceiveTransactionDetailsViewModel {
    static func preview() -> ReceiveTransactionDetailsViewModel {
        ReceiveTransactionDetailsViewModel(
            tokens: .init(tokenIconInfo: .transactionDetailsPreview(name: "Tether"), amountText: "+350.31 USDT", fiatText: "$350.31"),
            sender: .init(label: "From address", actor: .address(short: previewTruncatedAddress, blockiesImage: nil), onCopy: {})
        )
    }

    static func previewInProgress() -> ReceiveTransactionDetailsViewModel {
        ReceiveTransactionDetailsViewModel(
            tokens: .init(tokenIconInfo: .transactionDetailsPreview(name: "Tether"), amountText: "+350.31 USDT", fiatText: "$350.31"),
            statusBanner: .init(kind: .inProgress, title: "Awaiting funds"),
            sender: .init(label: "From address", actor: .address(short: previewTruncatedAddress, blockiesImage: nil), onCopy: {})
        )
    }
}
#endif // DEBUG
