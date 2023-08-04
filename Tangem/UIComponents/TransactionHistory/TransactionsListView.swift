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
    let items: [TransactionViewModel]
}

struct TransactionsListView: View {
    let state: State
    let exploreAction: () -> Void
    let reloadButtonAction: () -> Void
    let isReloadButtonBusy: Bool
    let buyButtonAction: (() -> Void)?
    let fetchMoreBlock: (() -> Void)?

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
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            Button(action: exploreAction) {
                HStack(spacing: 4) {
                    Assets.compass.image
                        .foregroundColor(Colors.Icon.informative)

                    Text(Localization.commonExplorer)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .notSupported:
            notSupportedContent
        case .loading:
            loadingContent
        case .loaded(let items):
            transactionsContent(transactionItems: items)
        case .error:
            errorContent
        }
    }

    @ViewBuilder
    private var notSupportedContent: some View {
        VStack(spacing: 20) {
            Assets.compassBig.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryNotSupportedDescription)
                .multilineTextAlignment(.center)
                .lineSpacing(Constants.lineSpacing)
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
    private var noTransactionsContent: some View {
        VStack(spacing: 20) {
            Assets.coinSlot.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryEmptyTransactions)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

            if let buyButtonAction = buyButtonAction {
                simpleButton(with: Localization.commonBuy, and: buyButtonAction)
            }
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 20) {
            Assets.fileExclamationMark.image
                .foregroundColor(Colors.Icon.informative)

            Text(Localization.transactionHistoryErrorFailedToLoad)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineSpacing(Constants.lineSpacing)
                .padding(.horizontal, 36)

            buttonWithLoader(title: Localization.commonReload, action: reloadButtonAction, isLoading: isReloadButtonBusy)
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private func transactionsContent(transactionItems: [TransactionListItem]) -> some View {
        if transactionItems.isEmpty {
            noTransactionsContent
        } else {
            LazyVStack(spacing: 12) {
                header

                ForEach(transactionItems, id: \.id) { item in
                    Section {
                        LazyVStack(spacing: 12) {
                            ForEach(item.items, id: \.id) { record in
                                TransactionView(transactionRecord: record)
                            }
                        }
                    } header: {
                        HStack {
                            Text(item.header)
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                            Spacer()
                        }
                    }
                }

                if let fetchMoreBlock = fetchMoreBlock {
                    ActivityIndicatorView(style: .medium, color: .gray)
                        .padding(.vertical)
                        .onAppear {
                            fetchMoreBlock()
                        }
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func simpleButton(with title: String, and action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
        }
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(10)
    }

    @ViewBuilder
    private func buttonWithLoader(title: String, action: @escaping () -> Void, isLoading: Bool) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .style(Fonts.Bold.subheadline, color: isLoading ? Color.clear : Colors.Text.primary1)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
                        .hidden(!isLoading)
                        .disabled(!isLoading)
                )
        }
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(10)
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

extension TransactionsListView {
    enum Constants {
        /// An approximate value from the design
        static let lineSpacing: CGFloat = 3.5
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    static let listItems = [
        TransactionListItem(
            header: "Today",
            items: [
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "01:00",
                    transferAmount: "-15 wxDAI",
                    transactionType: .send,
                    status: .inProgress
                ),
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "02:00",
                    transferAmount: "-15 wxDAI",
                    transactionType: .send,
                    status: .confirmed
                ),
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "+15 wxDAI",
                    transactionType: .receive,
                    status: .confirmed
                ),
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "08:00",
                    transferAmount: "-15 wxDAI",
                    transactionType: .send,
                    status: .confirmed
                ),
                TransactionViewModel(
                    destination: TransactionViewModel.TransactionType.receive.localizeDestination(for: "0x0123...baced"),
                    timeFormatted: "15:00",
                    transferAmount: "+15 wxDAI",
                    transactionType: .receive,
                    status: .confirmed
                ),
            ]
        ),
        TransactionListItem(
            header: "Yesterday",
            items: [
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    transactionType: .send,
                    status: .confirmed
                ),
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "09:00",
                    transferAmount: "-15 wxDAI",
                    transactionType: .send,
                    status: .confirmed
                ),
            ]
        ),
        TransactionListItem(
            header: "02.05.23",
            items: [
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "05:00",
                    transferAmount: "-15 wxDAI",
                    transactionType: .send,
                    status: .confirmed
                ),
                TransactionViewModel(
                    destination: "0x0123...baced",
                    timeFormatted: "08:00",
                    transferAmount: "-15 wxDAI",
                    transactionType: .send,
                    status: .confirmed
                ),
                TransactionViewModel(
                    destination: TransactionViewModel.TransactionType.approval.localizeDestination(for: "0x0123...baced"),
                    timeFormatted: "18:32",
                    transferAmount: "-0.0012 ETH",
                    transactionType: .approval,
                    status: .confirmed
                ),
            ]
        ),
    ]

    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                TransactionsListView(state: .notSupported, exploreAction: {}, reloadButtonAction: {}, isReloadButtonBusy: false, buyButtonAction: {}, fetchMoreBlock: {})

                TransactionsListView(state: .loading, exploreAction: {}, reloadButtonAction: {}, isReloadButtonBusy: false, buyButtonAction: {}, fetchMoreBlock: {})

                TransactionsListView(state: .loaded([]), exploreAction: {}, reloadButtonAction: {}, isReloadButtonBusy: false, buyButtonAction: {}, fetchMoreBlock: {})

                TransactionsListView(state: .error(""), exploreAction: {}, reloadButtonAction: {}, isReloadButtonBusy: false, buyButtonAction: {}, fetchMoreBlock: {})
            }
            .padding(.horizontal, 16)
        }
        .preferredColorScheme(.dark)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))

        ScrollView {
            TransactionsListView(
                state: .loaded(listItems),
                exploreAction: {},
                reloadButtonAction: {},
                isReloadButtonBusy: false,
                buyButtonAction: {},
                fetchMoreBlock: {}
            )
            .padding(.horizontal, 16)
        }
        .preferredColorScheme(.dark)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
