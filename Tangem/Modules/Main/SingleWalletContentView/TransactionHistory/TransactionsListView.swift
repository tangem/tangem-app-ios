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
    let exploreAction: () -> Void

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
            Text("Transactions")
                .style(
                    Fonts.Bold.footnote,
                    color: Colors.Text.tertiary
                )
            Spacer()
            Button(action: exploreAction) {
                HStack {
                    Assets.compass.image
                        .foregroundColor(Colors.Icon.informative)

                    Text("Explore")
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    @ViewBuilder
    private var content: some View {
        if transactionItems.isEmpty {
            VStack(spacing: 20) {
                Assets.coinSlot.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)

                Text("You don't have any transactions yet")
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }
            .padding(.horizontal, 60)
            .padding(.top, 53)
            .padding(.bottom, 86)
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
                    destination: "0x01230...3feed",
                    dateTime: "In progress...",
                    transferAmount: "+443 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "05:10",
                    transferAmount: "+50 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "In progress...",
                    transferAmount: "+443 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "05:10",
                    transferAmount: "+50 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "In progress...",
                    transferAmount: "+443 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "05:10",
                    transferAmount: "+50 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "In progress...",
                    transferAmount: "+443 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "05:10",
                    transferAmount: "+50 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "In progress...",
                    transferAmount: "+443 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "05:10",
                    transferAmount: "+50 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "In progress...",
                    transferAmount: "+443 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x01230...3feed",
                    dateTime: "05:10",
                    transferAmount: "+50 wxDAI",
                    canBePushed: false,
                    direction: .incoming,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
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
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
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
                    destination: "0x012...baced",
                    dateTime: "In progress...",
                    transferAmount: "-0.5 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    dateTime: "05:00",
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
            TransactionsListView(transactionItems: listItems) {}
        }
        .padding(.horizontal, 16)

        PerfList {
            TransactionsListView(transactionItems: []) {}
        }
        .padding(.horizontal, 16)
    }
}
