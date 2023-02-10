//
//  TransactionsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionListItem: Hashable, Identifiable {
    var id: Int { hashValue }

    let header: String
    let items: [TransactionRecord]
}

struct TransactionsListView: View {
    let transactionItems: [TransactionListItem]

    var body: some View {
        VStack {
            header

            content
        }
        .padding(.top, 13)
        .padding([.horizontal, .bottom], 16)
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Text(Localization.transactionHistoryTitle)
                .style(
                    Fonts.Bold.footnote,
                    color: Colors.Text.tertiary
                )
            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        if transactionItems.isEmpty {
            VStack(spacing: 20) {
                Assets.coinSlot.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)

                Text(Localization.transactionHistoryEmptyTransactions)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }
            .padding(.horizontal, 60)
            .padding(.top, 53)
            .padding(.bottom, 70)
        } else {
            ForEach(transactionItems, id: \.id) { item in
                Section {
                    VStack(spacing: 10) {
                        ForEach(item.items, id: \.id) { record in
                            TransactionView(transactionRecord: record)
                        }
                    }
                } header: {
                    HStack {
                        Text(item.header)
                            .style(
                                Fonts.Regular.footnote,
                                color: Colors.Text.tertiary
                            )
                            .padding(.vertical, 12)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    static let listItems = [
        TransactionListItem(
            header: "Today",
            items: [
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
            ]
        ),
        TransactionListItem(
            header: "Yesterday",
            items: [
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
            ]
        ),
        TransactionListItem(
            header: "02.05.23",
            items: [
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    time: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
            ]
        ),
    ]
    static var previews: some View {
        PerfList {
            TransactionsListView(transactionItems: listItems)
        }
        .padding(.horizontal, 16)

        PerfList {
            TransactionsListView(transactionItems: [])
        }
        .padding(.horizontal, 16)
    }
}
