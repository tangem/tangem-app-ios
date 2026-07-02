//
//  TransactionDetailsPreviewFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI

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

    // MARK: - Swap

    static func swapInProgress() -> TransactionDetailsViewModel {
        swap(title: "Swapping", status: .inProgress, data: .init(
            stage: .inProgress, source: swapSource, destination: swapDestination, isDestinationEstimated: true,
            statusBanner: .init(kind: .inProgress, title: "Deposit confirmed"),
            provider: swapProvider, rate: "1 POL ≈ 0.36 USDT", networkFee: "0.00056 ETH", action: nil
        ))
    }

    static func swapFinished() -> TransactionDetailsViewModel {
        swap(title: "Swapped", status: .confirmed, data: .init(
            stage: .finished, source: swapSource, destination: swapDestination, isDestinationEstimated: false,
            statusBanner: .init(kind: .success, title: "Funds received"),
            provider: swapProvider, rate: "1 POL ≈ 0.36 USDT", networkFee: "0.00056 ETH", action: nil
        ))
    }

    static func swapFailed() -> TransactionDetailsViewModel {
        swap(title: "Swapping failed", status: .failed, data: .init(
            stage: .unsuccessful, source: swapSource, destination: swapDestination, isDestinationEstimated: false,
            statusBanner: .init(kind: .warning, title: "Failed", subtitle: "Visit provider's website to refund your money"),
            provider: swapProvider, rate: "1 POL ≈ 0.36 USDT", networkFee: nil, action: nil
        ))
    }

    // MARK: - Onramp

    static func onrampInProgress() -> TransactionDetailsViewModel {
        onramp(title: "Top up", status: .inProgress, data: .init(
            stage: .inProgress, paid: onrampPaid, received: onrampReceived, isReceivedEstimated: true,
            statusBanner: .init(kind: .inProgress, title: "Awaiting payment"),
            provider: onrampProvider, rate: "1 BTC ≈ 75,200.00 USD", action: nil
        ))
    }

    static func onrampFinished() -> TransactionDetailsViewModel {
        onramp(title: "Top up", status: .confirmed, data: .init(
            stage: .finished, paid: onrampPaid, received: onrampReceived, isReceivedEstimated: false,
            statusBanner: .init(kind: .success, title: "Funds received"),
            provider: onrampProvider, rate: "1 BTC ≈ 75,200.00 USD", action: nil
        ))
    }

    static func onrampFailed() -> TransactionDetailsViewModel {
        onramp(title: "Top up failed", status: .failed, data: .init(
            stage: .unsuccessful, paid: onrampPaid, received: onrampReceived, isReceivedEstimated: false,
            statusBanner: .init(kind: .warning, title: "Failed", subtitle: "The payment was not completed"),
            provider: onrampProvider, rate: "1 BTC ≈ 75,200.00 USD", action: nil
        ))
    }

    // MARK: - Tokens block

    static func tokensSingle() -> TransactionDetailsTokensViewData {
        .init(tokenIconInfo: icon("Tether", color: .green), amountText: "+350.31 USDT", fiatText: "$350.31")
    }

    static func tokensPair() -> TransactionDetailsTokensViewData {
        .init(
            from: .init(direction: .init(label: "From", actor: nil), icon: .token(icon("Tether", color: .green)), amountText: "− 390 USDT", fiatText: "$391.12"),
            to: .init(direction: .init(label: "To", actor: nil), icon: .token(icon("Polygon", color: .purple)), amountText: "~ 1,800.00 POL", fiatText: "$391.12")
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

    static let swapSource = SwapTransactionDetailsViewData.Leg(amount: "390", symbol: "USDT", tokenIconInfo: icon("Tether"))
    static let swapDestination = SwapTransactionDetailsViewData.Leg(amount: "1,800.00", symbol: "POL", tokenIconInfo: icon("Polygon", color: .purple))
    static let swapProvider = TransactionDetailsProviderInfo(name: "DEX • Mercuryo", iconURL: nil, onTap: {})

    static let onrampPaid = OnrampTransactionDetailsViewData.PaidLeg(amount: "3,903.02", symbol: "SEK", fiatPrice: "$ 391.12", flagIconURL: nil)
    static let onrampReceived = OnrampTransactionDetailsViewData.ReceivedLeg(
        destination: .account(name: "Main account", icon: .composite(backgroundColor: .blue, nameMode: .letter("M"))),
        amount: "0.0052",
        symbol: "BTC",
        fiatPrice: "$ 390.84",
        tokenIconInfo: icon("Bitcoin", color: .orange)
    )
    static let onrampProvider = TransactionDetailsProviderInfo(name: "Mercuryo", iconURL: nil, onTap: {})

    static func icon(_ name: String, color: Color? = nil) -> TokenIconInfo {
        TokenIconInfo(name: name, blockchainIconAsset: nil, imageURL: nil, isCustom: false, customTokenColor: color)
    }

    static func header(title: String, operationIcon: TransactionViewIconViewData) -> TransactionDetailsHeaderViewData {
        .init(title: title, date: "Jan 20 2026, 9:24 PM", operationIcon: operationIcon, menuActions: menuActions, onClose: {})
    }

    static func swap(title: String, status: TransactionViewModel.Status, data: SwapTransactionDetailsViewData) -> TransactionDetailsViewModel {
        .init(
            header: header(title: title, operationIcon: .init(type: .swap, status: status, isOutgoing: true)),
            content: .swap(data)
        )
    }

    static func onramp(title: String, status: TransactionViewModel.Status, data: OnrampTransactionDetailsViewData) -> TransactionDetailsViewModel {
        .init(
            header: header(title: title, operationIcon: .init(type: .transfer, status: status, isOutgoing: false)),
            content: .onramp(data)
        )
    }
}
