//
//  TransactionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionView: View {
    let viewModel: TransactionViewModel

    var body: some View {
        HStack(spacing: 12) {
            viewModel.icon
                .renderingMode(.template)
                .foregroundColor(viewModel.iconColor)
                .padding(10)
                .background(viewModel.iconBackgroundColor)
                .cornerRadiusContinuous(20)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(viewModel.name)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    if viewModel.inProgress {
                        Assets.pendingTxIndicator.image
                    }

                    Spacer()

                    if let amount = viewModel.formattedAmount {
                        SensitiveText(amount)
                            .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                    }
                }

                HStack(spacing: 6) {
                    Text(viewModel.localizeDestination)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text(viewModel.subtitleText)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

struct TransactionView_Previews: PreviewProvider {
    static let previewViewModels: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "10:45",
            amount: "443 wxDAI",
            isOutgoing: false,
            transactionType: .transfer,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "05:10",
            amount: "50 wxDAI",
            isOutgoing: false,
            transactionType: .transfer,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"),
            timeFormatted: "00:04",
            amount: "0 wxDAI",
            isOutgoing: true,
            transactionType: .approval,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619"),
            timeFormatted: "15:00",
            amount: "15 wxDAI",
            isOutgoing: true,
            transactionType: .swap,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "16:23",
            amount: "0.000000532154 ETH",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "16:23",
            amount: "0.532154 USDT",
            isOutgoing: true,
            transactionType: .swap,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "18:32",
            amount: "0.0012 ETH",
            isOutgoing: true,
            transactionType: .approval,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("0xeEDBa2484aAF940f37cd3CD21a5D7C4A7DAfbfC0"),
            timeFormatted: "18:32",
            amount: "0.0012 ETH",
            isOutgoing: true,
            transactionType: .approval,
            status: .inProgress
        ),
    ]

    static let figmaViewModels1: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "−0.500913 BTC",
            isOutgoing: true,
            transactionType: .custom(name: "Sending"),
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .approval,
            status: .inProgress
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .inProgress
        ),
    ]

    static let figmaViewModels2: [TransactionViewModel] = [
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .user("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "−0.500913 BTC",
            isOutgoing: true,
            transactionType: .custom(name: "Sending"),
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .approval,
            status: .confirmed
        ),
        TransactionViewModel(
            hash: UUID().uuidString,
            interactionAddress: .contract("33BdfS...ga2B"),
            timeFormatted: "10:45",
            amount: "+0.500913 BTC",
            isOutgoing: false,
            transactionType: .swap,
            status: .failed
        ),
    ]

    static var previews: some View {
        VStack {
            ForEach(previewViewModels) {
                TransactionView(viewModel: $0)
            }
        }
        .padding()
    }
}
