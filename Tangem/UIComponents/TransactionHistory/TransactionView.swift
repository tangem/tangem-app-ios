//
//  TransactionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionView: View {
    let transactionRecord: TransactionRecord

    var body: some View {
        HStack(spacing: 12) {
            txTypeIcon
                .renderingMode(.template)
                .foregroundColor(transactionRecord.status.iconColor)
                .padding(10)
                .background(transactionRecord.status.iconBackgroundColor)
                .cornerRadiusContinuous(20)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(transactionRecord.transactionType.name)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    if case .inProgress = transactionRecord.status {
                        Assets.pendingTxIndicator.image
                    }

                    Spacer()

                    Text(transactionRecord.transferAmount)
                        .style(Fonts.Regular.subheadline, color: transactionRecord.transactionType.amountTextColor)
                }

                HStack(spacing: 6) {
                    Text(transactionRecord.destination)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    Spacer()

                    Text(transactionRecord.timeFormatted)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
    }

    private var txTypeIcon: Image {
        switch transactionRecord.transactionType {
        case .receive:
            return Assets.arrowDownMini.image
        case .send:
            return Assets.arrowUpMini.image
        case .swap:
            return Assets.exchangeMini.image
        case .approval:
            return Assets.approve.image
        }
    }

    private var subtitleText: String {
        switch transactionRecord.status {
        case .confirmed:
            return transactionRecord.timeFormatted
        case .inProgress:
            return Localization.transactionHistoryTxInProgress
        }
    }
}

struct TransactionView_Previews: PreviewProvider {
    static func destination(for transactionType: TransactionRecord.TransactionType, address: String) -> String {
        transactionType.localizeDestination(for: address)
    }

    static let incomingInProgressRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .receive, address: "0x01230...3feed"),
        timeFormatted: "10:45",
        transferAmount: "+443 wxDAI",
        transactionType: .receive,
        status: .inProgress
    )

    static let incomingConfirmedRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .receive, address: "0x01230...3feed"),
        timeFormatted: "05:10",
        transferAmount: "+50 wxDAI",
        transactionType: .receive,
        status: .confirmed
    )

    static let outgoingInProgressRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .receive, address: "0x012...baced"),
        timeFormatted: "00:04",
        transferAmount: "-0.5 wxDAI",
        transactionType: .send,
        status: .inProgress
    )

    static let outgoingConfirmedRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .receive, address: "0x0123...baced"),
        timeFormatted: "15:00",
        transferAmount: "-15 wxDAI",
        transactionType: .send,
        status: .confirmed
    )

    static let incomingSwapRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .swap(type: .buy), address: "0x0123...baced"),
        timeFormatted: "16:23",
        transferAmount: "+0.000000532154 ETH",
        transactionType: .swap(type: .buy),
        status: .inProgress
    )

    static let outgoingSwapRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .swap(type: .sell), address: "0x0123...baced"),
        timeFormatted: "16:23",
        transferAmount: "-0.532154 USDT",
        transactionType: .swap(type: .sell),
        status: .confirmed
    )

    static let approveConfirmedRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .approval, address: "0x0123...baced"),
        timeFormatted: "18:32",
        transferAmount: "-0.0012 ETH",
        transactionType: .approval,
        status: .confirmed
    )

    static let approveInProgressRecord = TransactionRecord(
        amountType: .coin,
        destination: destination(for: .approval, address: "0x0123...baced"),
        timeFormatted: "18:32",
        transferAmount: "-0.0012 ETH",
        transactionType: .approval,
        status: .inProgress
    )

    static var previews: some View {
        VStack {
            TransactionView(transactionRecord: incomingInProgressRecord)
            TransactionView(transactionRecord: incomingConfirmedRecord)
            TransactionView(transactionRecord: outgoingInProgressRecord)
            TransactionView(transactionRecord: outgoingConfirmedRecord)
            TransactionView(transactionRecord: incomingSwapRecord)
            TransactionView(transactionRecord: outgoingSwapRecord)
            TransactionView(transactionRecord: approveInProgressRecord)
            TransactionView(transactionRecord: approveConfirmedRecord)
        }
        .padding()
    }
}
