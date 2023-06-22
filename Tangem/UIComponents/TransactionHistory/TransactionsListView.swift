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
    let state: State
    let exploreAction: (() -> Void)
    let reloadButtonAction: (() -> Void)
    let buyButtonAction: (() -> Void)

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
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

            Button(action: exploreAction) {
                HStack {
                    Assets.compass.image
                        .foregroundColor(Colors.Icon.informative)

                    Text(Localization.commonExplore)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loaded(let items):
            transactionsContent(transactionItems: items)
        case .error:
            errorContent
        case .loading:
            loadingContent
        case .notSupported:
            notSupportedContent
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        VStack(spacing: 12) {
            header
                .padding(.horizontal, 16)

            ForEach(0 ... 2) { _ in
                TokenListItemLoadingPlaceholderView(style: .transactionHistory)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack {
            Assets.fileExclamationMark.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryErrorFailedToLoad)
                .multilineTextAlignment(.center)
                .style(
                    Fonts.Bold.footnote,
                    color: Colors.Text.tertiary
                )
        }
        .padding(.top, 28)
        .padding(.bottom, 126)
    }

    @ViewBuilder
    private var notSupportedContent: some View {
        VStack(spacing: 20) {
            Assets.compassBig.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryNotSupportedDescription)
                .multilineTextAlignment(.center)
                .lineSpacing(3.5)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 36)

            FixedSizeButtonWithLeadingIcon(
                title: Localization.commonExploreTransactionHistory,
                icon: Assets.arrowRightUpMini.image,
                action: exploreAction
            )
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private func transactionsContent(transactionItems: [TransactionListItem]) -> some View {
        if transactionItems.isEmpty {
            VStack(spacing: 20) {
                Assets.coinSlot.image
                    .foregroundColor(Colors.Icon.informative)

                Text(Localization.transactionHistoryEmptyTransactions)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }
            .padding(.top, 53)
            .padding(.bottom, 70)
        } else {
            VStack {
                header

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
}

extension TransactionsListView {
    enum State {
        case loading
        case error(Error)
        case loaded([TransactionListItem])
        case notSupported
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
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .inProgress
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
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
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
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
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
                TransactionRecord(
                    amountType: .coin,
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    canBePushed: false,
                    direction: .outgoing,
                    status: .confirmed
                ),
            ]
        ),
    ]

    static var previews: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                TransactionsListView(state: .notSupported, exploreAction: {}, reloadButtonAction: {}, buyButtonAction: {})

                TransactionsListView(state: .loading, exploreAction: {}, reloadButtonAction: {}, buyButtonAction: {})

                TransactionsListView(state: .loaded([]), exploreAction: {}, reloadButtonAction: {}, buyButtonAction: {})

                TransactionsListView(state: .error(""), exploreAction: {}, reloadButtonAction: {}, buyButtonAction: {})

            }
            .padding(.horizontal, 16)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))

        ScrollView {
            LazyVStack {
                TransactionsListView(state: .loaded(listItems), exploreAction: {}, reloadButtonAction: {}, buyButtonAction: {})
            }
        }
        .padding(.horizontal, 16)
    }
}
