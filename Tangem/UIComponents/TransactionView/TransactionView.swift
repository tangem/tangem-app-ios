//
//  TransactionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import Kingfisher

struct TransactionView: View {
    let viewModel: TransactionViewModel

    var body: some View {
        HStack(spacing: 12) {
            TransactionViewIconView(data: viewModel.icon, size: .medium)

            textContent
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var textContent: some View {
        // we can use 2 row layout only when all the data is present
        // otherwise left or right part needs to be vertically centered
        if viewModel.localizeDestination != nil, viewModel.amount.formattedAmount != nil {
            twoRowsTextContent
        } else {
            twoColumnsTextContent
        }
    }

    private var twoRowsTextContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: .zero) {
                name
                Spacer(minLength: 8)
                amount
            }

            HStack(spacing: .zero) {
                description
                Spacer(minLength: 6)
                subtitle
            }
        }
    }

    private var twoColumnsTextContent: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: 4) {
                name
                description
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                amount
                subtitle
            }
        }
    }

    private var name: some View {
        HStack(spacing: 8) {
            Text(viewModel.name)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .multilineTextAlignment(.leading)
                .lineLimit(1)

            if viewModel.inProgress {
                ProgressDots(style: .small)
            }
        }
    }

    @ViewBuilder
    private var description: some View {
        if let localizeDestination = viewModel.getTransactionDescription() {
            Text(localizeDestination)
                .multilineTextAlignment(.leading)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
                .truncationMode(viewModel.transactionDescriptionTruncationMode)
        }
    }

    @ViewBuilder
    private var amount: some View {
        TransactionViewAmountView(data: viewModel.amount, size: .medium)
            // The amount has priority to show
            .layoutPriority(1)
    }

    private var subtitle: some View {
        Text(viewModel.subtitleText)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
    }
}

struct TransactionView_Previews: PreviewProvider {
    static let previewViewModels: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "10:45",
            amount: "443 wxDAI",
            isOutgoing: false,
            transactionType: .transfer,
            status: .inProgress,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "05:10",
            amount: "50 wxDAI",
            isOutgoing: false,
            transactionType: .transfer,
            status: .confirmed,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"),
            timeFormatted: "00:04",
            amount: "0 wxDAI",
            isOutgoing: true,
            transactionType: .approve,
            status: .confirmed,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"),
            timeFormatted: "15:00",
            amount: "15 wxDAI",
            isOutgoing: true,
            transactionType: .swap,
            status: .inProgress,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "16:23",
            amount: "0.000000532154 ETH",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "16:23",
            amount: "0.532154 USDT",
            isOutgoing: true,
            transactionType: .swap,
            status: .confirmed,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "18:32",
            amount: "0.0012 ETH",
            isOutgoing: true,
            transactionType: .approve,
            status: .confirmed,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "18:32",
            amount: "0.0012 ETH",
            isOutgoing: true,
            transactionType: .approve,
            status: .inProgress,
            isFromYieldContract: false
        ),
    ]

    static let figmaViewModels1: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "−0.500913 BTC",
            isOutgoing: true,
            transactionType: .operation(name: "Sending"),
            status: .inProgress,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .approve,
            status: .inProgress,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress,
            isFromYieldContract: false
        ),
    ]

    static let figmaViewModels2: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .user("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "−0.500913 BTC",
            isOutgoing: true,
            transactionType: .operation(name: "Sending"),
            status: .confirmed,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .approve,
            status: .confirmed,
            isFromYieldContract: false
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            index: 0,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .failed,
            isFromYieldContract: false
        ),
    ]

    static var previews: some View {
        Group {
            VStack {
                ForEach(previewViewModels) {
                    TransactionView(viewModel: $0)
                }
            }
            .padding()
            .previewDisplayName("previewViewModels")

            VStack {
                ForEach(figmaViewModels1) {
                    TransactionView(viewModel: $0)
                }
            }
            .padding()
            .previewDisplayName("figmaViewModels1")

            VStack {
                ForEach(figmaViewModels2) {
                    TransactionView(viewModel: $0)
                }
            }
            .padding()
            .previewDisplayName("figmaViewModels2")
        }
    }
}
