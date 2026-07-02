//
//  TransactionsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct TransactionsListView: View {
    let state: State
    let exploreAction: (() -> Void)?
    let exploreConfirmationDialog: Binding<ConfirmationDialogViewModel?>?
    let exploreTransactionAction: (String) -> Void
    let reloadButtonAction: () -> Void
    let isReloadButtonBusy: Bool
    let fetchMore: FetchMore?

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(Colors.Background.primary)
            .cornerRadiusContinuous(14)
    }

    private var header: some View {
        HStack {
            Text(Localization.commonTransactions)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            Spacer()

            if let exploreAction {
                Button(action: exploreAction) {
                    HStack(spacing: 4) {
                        Assets.compass.image
                            .renderingMode(.template)
                            .foregroundStyle(Colors.Icon.informative)

                        Text(Localization.commonExplorer)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }
                .ifLet(exploreConfirmationDialog) { view, exploreConfirmationDialogViewModel in
                    view.confirmationDialog(viewModel: exploreConfirmationDialogViewModel)
                }
            }
        }
        .padding(.horizontal, 16)
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

    private var notSupportedContent: some View {
        VStack(spacing: 20) {
            Assets.compassBig.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.transactionHistoryNotSupportedDescription)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 36)

            if let exploreAction {
                makeExploreTransactionHistoryButton(
                    withTitle: Localization.commonExploreTransactionHistory,
                    hasFixedSize: true,
                    exploreAction: exploreAction
                )
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 28)
    }

    private var loadingContent: some View {
        VStack(spacing: 12) {
            header

            ForEach(0 ... 2) { _ in
                TokenListItemLoadingPlaceholderView(style: .transactionHistory)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private var noTransactionsContent: some View {
        VStack(spacing: 22) {
            Assets.emptyHistory.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.transactionHistoryEmptyTransactions)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 16)

            if let exploreAction {
                makeExploreTransactionHistoryButton(
                    withTitle: Localization.commonExplore,
                    hasFixedSize: true,
                    exploreAction: exploreAction
                )
            }
        }
        .padding(.vertical, 28)
    }

    private var errorContent: some View {
        VStack(spacing: 20) {
            Assets.fileExclamationMark.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.inactive)

            Text(Localization.transactionHistoryErrorFailedToLoad)
                .multilineTextAlignment(.center)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.horizontal, 36)

            HStack(spacing: 8.0) {
                makeReloadTransactionHistoryButton()

                if let exploreAction {
                    makeExploreTransactionHistoryButton(
                        withTitle: Localization.commonExplore,
                        hasFixedSize: false,
                        exploreAction: exploreAction
                    )
                }
            }
            .padding(.horizontal, 16.0)
        }
        .padding(.vertical, 28)
    }

    @ViewBuilder
    private func transactionsContent(transactionItems: [TransactionListItem]) -> some View {
        if transactionItems.isEmpty {
            noTransactionsContent
        } else {
            LazyVStack(spacing: 0) {
                ForEach(transactionItems.indexed(), id: \.1.id) { sectionIndex, sectionItem in
                    VStack(spacing: 0) {
                        if sectionIndex == 0 {
                            header
                        }

                        makeSectionHeader(for: sectionItem, atIndex: sectionIndex, withVerticalPadding: true)
                    }

                    ForEach(sectionItem.items.indexed(), id: \.1.id) { cellIndex, cellItem in
                        Button {
                            exploreTransactionAction(cellItem.hash)
                        } label: {
                            // Extra padding to implement "cell spacing" without resorting to VStack spacing
                            TransactionView(viewModel: cellItem)
                                .padding(.bottom, cellIndex == (sectionItem.items.count - 1) ? 0 : 16)
                        }
                    }
                }

                if let fetchMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
                        .padding(.vertical)
                        .onAppear {
                            fetchMore.start()
                        }
                        .id(fetchMore.id)
                }
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func makeSectionHeader(
        for item: TransactionListItem,
        atIndex sectionIndex: Int,
        withVerticalPadding useVerticalPadding: Bool
    ) -> some View {
        HStack {
            Text(item.header)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, useVerticalPadding ? 14 : 0)
    }

    private func makeExploreTransactionHistoryButton(
        withTitle title: String,
        hasFixedSize: Bool,
        exploreAction: @escaping () -> Void
    ) -> some View {
        Group {
            if hasFixedSize {
                FixedSizeButtonWithLeadingIcon(
                    title: title,
                    icon: Assets.arrowRightUpMini.image,
                    style: .default,
                    action: exploreAction
                )
                .overrideBackgroundColor(Constants.buttonBackgroundColor)
            } else {
                FlexySizeButtonWithLeadingIcon(
                    title: title,
                    icon: Assets.arrowRightUpMini.image,
                    action: exploreAction
                )
                .overrideBackgroundColor(Constants.buttonBackgroundColor)
            }
        }
        .ifLet(exploreConfirmationDialog) { view, exploreConfirmationDialogViewModel in
            view.confirmationDialog(viewModel: exploreConfirmationDialogViewModel)
        }
    }

    private func makeReloadTransactionHistoryButton() -> some View {
        FlexySizeButtonWithLeadingIcon(
            title: Localization.commonReload,
            icon: Assets.reload.image,
            action: reloadButtonAction
        )
        .overrideBackgroundColor(Constants.buttonBackgroundColor)
        .overlay(
            ZStack {
                Constants.buttonBackgroundColor
                    .cornerRadiusContinuous(FlexySizeButtonWithLeadingIcon.Constants.cornerRadius)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.primary1))
            }
            .hidden(!isReloadButtonBusy)
        )
    }
}

extension TransactionsListView {
    enum State: Equatable {
        case loading
        case error(Error)
        case loaded([TransactionListItem])
        case notSupported

        var isLoaded: Bool {
            if case .loaded = self {
                return true
            }
            return false
        }

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.error, .error): return true
            case (.loaded(let lhsItems), .loaded(let rhsItems)): return lhsItems == rhsItems
            case (.notSupported, .notSupported): return true
            default: return false
            }
        }
    }
}

// MARK: - Constants

extension TransactionsListView {
    enum Constants {
        static let buttonBackgroundColor = Colors.Button.secondary
    }
}

#if DEBUG

final class TxHistoryModel: ObservableObject {
    @Published var state: TransactionsListView.State

    static let oldItems = [
        TransactionListItem(
            header: "Yesterday",
            items: TransactionViewPreviewData.previewViewModels
        ),
        TransactionListItem(
            header: "02.05.23",
            items: TransactionViewPreviewData.previewViewModels
        ),
    ]

    static let todayItems = [
        TransactionListItem(
            header: "Today",
            items: TransactionViewPreviewData.previewViewModels
        ),
    ]

    private var onlyOldItems = true

    init(state: TransactionsListView.State) {
        self.state = state
    }

    func toggleState() {
        switch state {
        case .loading:
            state = .loaded(Self.oldItems)
        case .loaded:
            if onlyOldItems {
                state = .loaded(Self.todayItems + Self.oldItems)
                onlyOldItems = false
                return
            }

            state = .error("Don't touch this!!!")
            onlyOldItems = true
        case .error:
            state = .notSupported
        case .notSupported:
            state = .loading
        }
    }
}

struct TransactionsListPreview: View {
    @ObservedObject var model: TxHistoryModel

    var body: some View {
        VStack {
            Button(action: model.toggleState) {
                Text("Toggle state")
            }

            ScrollView {
                TransactionsListView(
                    state: model.state,
                    exploreAction: {},
                    exploreConfirmationDialog: nil,
                    exploreTransactionAction: { _ in },
                    reloadButtonAction: {},
                    isReloadButtonBusy: false,
                    fetchMore: nil
                )
                .animation(.default, value: model.state)
                .padding(.horizontal, 16)
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}

@available(iOS 17.0, *)
#Preview("Yesterday") {
    @Previewable @StateObject var model = TxHistoryModel(state: .loaded(TxHistoryModel.oldItems))

    TransactionsListPreview(model: model)
}

@available(iOS 17.0, *)
#Preview("Today") {
    @Previewable @StateObject var model = TxHistoryModel(
        state: .loaded(TxHistoryModel.todayItems + TxHistoryModel.oldItems)
    )

    TransactionsListPreview(model: model)
}

@available(iOS 17.0, *)
#Preview("Figma") {
    @Previewable @StateObject var model = TxHistoryModel(
        state: .loaded([
            TransactionListItem(header: "Today", items: TransactionViewPreviewData.figmaViewModels1),
            TransactionListItem(header: "Yesterday", items: TransactionViewPreviewData.figmaViewModels2),
        ])
    )

    TransactionsListPreview(model: model)
}

@available(iOS 17.0, *)
#Preview("Empty") {
    @Previewable @StateObject var model = TxHistoryModel(state: .loaded([]))

    TransactionsListPreview(model: model)
}

@available(iOS 17.0, *)
#Preview("Loading") {
    @Previewable @StateObject var model = TxHistoryModel(state: .loading)

    TransactionsListPreview(model: model)
}

@available(iOS 17.0, *)
#Preview("Not supported") {
    @Previewable @StateObject var model = TxHistoryModel(state: .notSupported)

    TransactionsListPreview(model: model)
}

@available(iOS 17.0, *)
#Preview("Error") {
    @Previewable @StateObject var model = TxHistoryModel(state: .error("eror!"))

    TransactionsListPreview(model: model)
}

#endif // DEBUG
