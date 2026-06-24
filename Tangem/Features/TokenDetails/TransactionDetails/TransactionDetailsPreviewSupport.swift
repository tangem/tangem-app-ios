//
//  TransactionDetailsPreviewSupport.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if DEBUG
import SwiftUI
import TangemAccounts
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

// MARK: - Swap

extension SwapTransactionDetailsViewModel {
    private static var previewSource: Leg {
        .init(amount: "390", symbol: "USDT", tokenIconInfo: .transactionDetailsPreview(name: "Tether"))
    }

    private static var previewDestination: Leg {
        .init(amount: "1,800.00", symbol: "POL", tokenIconInfo: .transactionDetailsPreview(name: "Polygon", color: .purple))
    }

    private static var previewProvider: TransactionDetailsProvider {
        .init(name: "DEX • Mercuryo", iconURL: nil, onTap: {})
    }

    static func previewInProgress() -> SwapTransactionDetailsViewModel {
        SwapTransactionDetailsViewModel(
            stage: .inProgress, source: previewSource, destination: previewDestination, isDestinationEstimated: true,
            statusBanner: .init(kind: .inProgress, title: "Deposit confirmed"),
            provider: previewProvider, rate: "1 POL ≈ 0.36 USDT", networkFee: "0.00056 ETH"
        )
    }

    static func previewFinished() -> SwapTransactionDetailsViewModel {
        SwapTransactionDetailsViewModel(
            stage: .finished, source: previewSource, destination: previewDestination, isDestinationEstimated: false,
            statusBanner: .init(kind: .success, title: "Funds received"),
            provider: previewProvider, rate: "1 POL ≈ 0.36 USDT", networkFee: "0.00056 ETH"
        )
    }

    static func previewUnsuccessful() -> SwapTransactionDetailsViewModel {
        SwapTransactionDetailsViewModel(
            stage: .unsuccessful, source: previewSource, destination: previewDestination, isDestinationEstimated: false,
            statusBanner: .init(kind: .warning, title: "Failed", subtitle: "Visit provider's website to refund your money"),
            provider: previewProvider, rate: "1 POL ≈ 0.36 USDT", networkFee: nil
        )
    }
}

// MARK: - Onramp

extension OnrampTransactionDetailsViewModel {
    private static var previewPaid: PaidLeg {
        .init(amount: "3,903.02", symbol: "SEK", fiatPrice: "$ 391.12", flagIconURL: nil)
    }

    private static var previewReceived: ReceivedLeg {
        .init(
            destinationName: "Main account",
            accountIcon: .composite(backgroundColor: .blue, nameMode: .letter("M")),
            amount: "0.0052",
            symbol: "BTC",
            fiatPrice: "$ 390.84",
            tokenIconInfo: .transactionDetailsPreview(name: "Bitcoin", color: .orange)
        )
    }

    private static var previewProvider: TransactionDetailsProvider {
        .init(name: "Mercuryo", iconURL: nil, onTap: {})
    }

    static func previewInProgress() -> OnrampTransactionDetailsViewModel {
        OnrampTransactionDetailsViewModel(
            stage: .inProgress, paid: previewPaid, received: previewReceived, isReceivedEstimated: true,
            statusBanner: .init(kind: .inProgress, title: "Awaiting payment"), provider: previewProvider, rate: "1 BTC ≈ 75,200.00 USD"
        )
    }

    static func previewFinished() -> OnrampTransactionDetailsViewModel {
        OnrampTransactionDetailsViewModel(
            stage: .finished, paid: previewPaid, received: previewReceived, isReceivedEstimated: false,
            statusBanner: .init(kind: .success, title: "Funds received"), provider: previewProvider, rate: "1 BTC ≈ 75,200.00 USD"
        )
    }

    static func previewUnsuccessful() -> OnrampTransactionDetailsViewModel {
        OnrampTransactionDetailsViewModel(
            stage: .unsuccessful, paid: previewPaid, received: previewReceived, isReceivedEstimated: false,
            statusBanner: .init(kind: .warning, title: "Failed", subtitle: "The payment was not completed"), provider: previewProvider, rate: "1 BTC ≈ 75,200.00 USD"
        )
    }
}
#endif // DEBUG
