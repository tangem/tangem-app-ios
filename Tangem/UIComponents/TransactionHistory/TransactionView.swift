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
            directionIcon
                .renderingMode(.template)
                .foregroundColor(transactionRecord.status.iconColor)
                .padding(10)
                .background(transactionRecord.status.iconColor.opacity(0.12))
                .cornerRadiusContinuous(20)
            VStack(alignment: .leading, spacing: 5) {
                Text(transactionRecord.destination)
                    .style(
                        Fonts.Regular.subheadline,
                        color: Colors.Text.primary1
                    )
                Text(subtitleText)
                    .style(
                        Fonts.Regular.footnote,
                        color: transactionRecord.status.textColor
                    )
            }
            Spacer()
            Text(transactionRecord.transferAmount)
                .style(
                    Fonts.Regular.subheadline,
                    color: Colors.Text.primary1
                )
        }
    }

    private var directionIcon: Image {
        switch transactionRecord.direction {
        case .incoming:
            return Assets.arrowDownMini.image
        case .outgoing:
            return Assets.arrowUpMini.image
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
    static let incomingInProgressRecord = TransactionRecord(
        amountType: .coin,
        destination: "0x01230...3feed",
        timeFormatted: "",
        transferAmount: "+443 wxDAI",
        canBePushed: false,
        direction: .incoming,
        status: .inProgress
    )

    static let incomingConfirmedRecord = TransactionRecord(
        amountType: .coin,
        destination: "0x01230...3feed",
        timeFormatted: "05:10",
        transferAmount: "+50 wxDAI",
        canBePushed: false,
        direction: .incoming,
        status: .confirmed
    )

    static let outgoingInProgressRecord = TransactionRecord(
        amountType: .coin,
        destination: "0x012...baced",
        timeFormatted: "00:04",
        transferAmount: "-0.5 wxDAI",
        canBePushed: false,
        direction: .outgoing,
        status: .inProgress
    )

    static let outgoingConfirmedRecord = TransactionRecord(
        amountType: .coin,
        destination: "0x0123...baced",
        timeFormatted: "15:00",
        transferAmount: "-15 wxDAI",
        canBePushed: false,
        direction: .outgoing,
        status: .confirmed
    )

    static var previews: some View {
        VStack {
            TransactionView(transactionRecord: incomingInProgressRecord)
            TransactionView(transactionRecord: incomingConfirmedRecord)
            TransactionView(transactionRecord: outgoingInProgressRecord)
            TransactionView(transactionRecord: outgoingConfirmedRecord)
        }
        .padding()
    }
}
