//
//  TransactionDetailsPreviewFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemAccounts
import TangemAssets
import TangemUI

@MainActor
enum TransactionDetailsPreviewFactory {
    // MARK: - Send / Receive

    static func sent() -> TransactionDetailsViewModel {
        single(title: "Sent", operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: true), data: .init(
            tokens: .init(tokenIconInfo: icon("Tether"), amountText: "−350.31 USDT", fiatText: "$350.31"),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: .init(label: "Recipient", actor: .address(short: truncatedAddress, blockiesImage: .init(image: nil)), onCopy: {}),
            info: .init(rows: [.init(id: "networkFee", title: "Network fee", content: .text("0.00056 ETH"))]),
            action: nil
        ))
    }

    static func received() -> TransactionDetailsViewModel {
        single(title: "Received", operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: false), data: .init(
            tokens: .init(tokenIconInfo: icon("Tether"), amountText: "+350.31 USDT", fiatText: "$350.31"),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: .init(label: "From address", actor: .address(short: truncatedAddress, blockiesImage: .init(image: nil)), onCopy: {}),
            info: nil,
            action: nil
        ))
    }

    // MARK: - Staking / Approve / Fee / Other (single-operation)

    static func staking() -> TransactionDetailsViewModel {
        single(title: "Staked", operationIcon: .init(type: .stake, status: .confirmed, isOutgoing: true), data: .init(
            tokens: .init(tokenIconInfo: icon("Ethereum", color: .blue), amountText: "1.00 ETH", fiatText: "$3,900.00"),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: nil,
            info: .init(rows: [
                .init(id: "validator", title: "Validator", content: .text("Aave")),
                .init(id: "networkFee", title: "Network fee", content: .text("0.0001 ETH")),
            ]),
            action: nil
        ))
    }

    static func approve() -> TransactionDetailsViewModel {
        single(title: "Approved", operationIcon: .init(type: .approve, status: .confirmed, isOutgoing: true), data: .init(
            tokens: .init(tokenIconInfo: icon("Tether", color: .green), amountText: "Unlimited USDT", fiatText: nil),
            statusBanner: nil,
            principalAmount: nil,
            counterparty: nil,
            info: .init(rows: [
                .init(id: "spender", title: "Spender", content: .text("Uniswap")),
                .init(id: "networkFee", title: "Network fee", content: .text("0.0001 ETH")),
            ]),
            action: nil
        ))
    }

    static func fee() -> TransactionDetailsViewModel {
        single(title: "Network Fee", operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: true), data: .init(
            tokens: .init(tokenIconInfo: icon("Ethereum", color: .blue), amountText: "−0.000015 ETH", fiatText: "$0.01"),
            statusBanner: nil,
            principalAmount: principalAmount(),
            counterparty: nil,
            info: .init(rows: [
                .init(id: "gasPrice", title: "Gas price", content: .text("32 Gwei")),
                .init(id: "gasUsed", title: "Gas used", content: .text("21,000")),
            ]),
            action: nil
        ))
    }

    static func other() -> TransactionDetailsViewModel {
        single(title: "Operation", operationIcon: .init(type: .operation(name: "Operation"), status: .confirmed, isOutgoing: false), data: .init(
            tokens: nil,
            statusBanner: nil,
            principalAmount: nil,
            counterparty: nil,
            info: .init(rows: [
                .init(id: "provider", title: "Provider", content: .link(.init(text: "Mercuryo", iconURL: nil, handler: {}))),
                .init(id: "rate", title: "Rate", content: .text("1 SOL ≈ 0.000075 BTC")),
            ]),
            action: nil
        ))
    }

    // MARK: - Yield

    static func yieldTokens() -> TransactionDetailsYieldTokensViewData {
        .init(
            accountIcon: .composite(backgroundColor: .purple, nameMode: .letter("M")),
            tokenIconInfo: icon("Tether", color: .green),
            amountText: "1,294.23 USDT",
            statusTitle: "Supplied"
        )
    }

    static func yieldEnabled() -> TransactionDetailsViewModel {
        viewModel(
            header: header(title: "Yield mode enabled", operationIcon: .init(type: .yieldEnter, status: .confirmed, isOutgoing: false)),
            content: .yield(TransactionDetailsYieldViewData(
                tokens: yieldTokens(),
                statusBanner: nil,
                info: .init(rows: [
                    .init(id: "validator", title: "Validator", content: .text("Aave")),
                    .init(id: "networkFee", title: "Network fee", content: .text("$4.45")),
                ]),
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

    // MARK: - Principal amount (fee "For sending")

    static func principalAmount() -> TransactionDetailsPrincipalAmountViewData {
        // [REDACTED_TODO_COMMENT]
        .init(icon: Assets.Send.arrowUp, label: "For sending", amount: "120.03 USDT", tokenIconInfo: icon("Tether", color: .green))
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

    /// Pair with the destination token still resolving — amount hidden, icon shimmering.
    static func tokensPairLoading() -> TransactionDetailsTokensViewData {
        .init(
            from: .init(direction: .init(label: "From", actor: nil), icon: .token(icon("Tether", color: .green)), amountText: "− 390 USDT", fiatText: "$391.12"),
            to: .init(direction: .init(label: "To", actor: nil), icon: .loading, amountText: nil, fiatText: nil)
        )
    }
}

// MARK: - Shared builders

private extension TransactionDetailsPreviewFactory {
    static let truncatedAddress = "33Bd321fS...ga21412B"

    // [REDACTED_TODO_COMMENT]
    static let menuActions: [TransactionDetailsHeaderViewData.MenuAction] = [
        .init(id: "transactionID", title: "Transaction ID", icon: Assets.Glyphs.copy, handler: {}),
        .init(id: "explore", title: "Explore", icon: Assets.Glyphs.explore, handler: {}),
    ]

    static let swapSource = SwapTransactionDetailsViewData.Leg(amount: "390", symbol: "USDT", tokenIconInfo: icon("Tether"))
    static let swapDestination = SwapTransactionDetailsViewData.Leg(amount: "1,800.00", symbol: "POL", tokenIconInfo: icon("Polygon", color: .purple))
    static let swapProvider = TransactionDetailsProviderInfo(name: "DEX • Mercuryo", iconURL: nil, onTap: {})

    static let onrampPaid = OnrampTransactionDetailsViewData.PaidLeg(amount: "3,903.02", symbol: "SEK", fiatPrice: "$ 391.12", flagIconURL: nil, isFlagLoading: false)
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

    static func single(title: String, operationIcon: TransactionViewIconViewData, data: TransactionDetailsSingleOperationViewData) -> TransactionDetailsViewModel {
        viewModel(header: header(title: title, operationIcon: operationIcon), content: .single(data))
    }

    static func swap(title: String, status: TransactionViewModel.Status, data: SwapTransactionDetailsViewData) -> TransactionDetailsViewModel {
        viewModel(
            header: header(title: title, operationIcon: .init(type: .swap, status: status, isOutgoing: true)),
            content: .swap(data)
        )
    }

    static func onramp(title: String, status: TransactionViewModel.Status, data: OnrampTransactionDetailsViewData) -> TransactionDetailsViewModel {
        viewModel(
            header: header(title: title, operationIcon: .init(type: .transfer, status: status, isOutgoing: false)),
            content: .onramp(data)
        )
    }

    static func viewModel(header: TransactionDetailsHeaderViewData, content: TransactionDetailsViewModel.Content) -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(
            header: header,
            content: content,
            recordUpdates: Empty(completeImmediately: false).eraseToAnyPublisher(),
            rebuild: { _ in (header, content) }
        )
    }
}
