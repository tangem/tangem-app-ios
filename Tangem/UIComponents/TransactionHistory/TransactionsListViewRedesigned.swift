//
//  TransactionsListViewRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TransactionsListViewRedesigned: View {
    let state: TransactionsListView.State
    let exploreAction: (() -> Void)?
    let exploreConfirmationDialog: Binding<ConfirmationDialogViewModel?>?
    let exploreTransactionAction: (String) -> Void
    let reloadButtonAction: () -> Void
    let isReloadButtonBusy: Bool
    let fetchMore: FetchMore?

    var body: some View {
        content
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .notSupported:
            StatusStateView(
                icon: Assets.compassBig,
                message: Localization.transactionHistoryNotSupportedDescription,
                primaryButton: exploreAction.map(notSupportedExploreButton),
                secondaryButton: nil
            )
            .ifLet(exploreConfirmationDialog) { view, dialog in
                view.confirmationDialog(viewModel: dialog)
            }
        case .loading:
            loadingContent
        case .loaded(let items):
            transactionsContent(transactionItems: items)
        case .error:
            StatusStateView(
                icon: Assets.fileExclamationMark,
                message: Localization.transactionHistoryErrorFailedToLoad,
                primaryButton: errorReloadButton,
                secondaryButton: exploreAction.map(errorExploreButton)
            )
            .ifLet(exploreConfirmationDialog) { view, dialog in
                view.confirmationDialog(viewModel: dialog)
            }
        }
    }

    @ViewBuilder
    private func transactionsContent(transactionItems: [TransactionListItem]) -> some View {
        if transactionItems.isEmpty {
            StatusStateView(
                icon: Assets.emptyHistory,
                message: Localization.transactionHistoryEmptyTransactions,
                primaryButton: exploreAction.map(emptyExploreButton),
                secondaryButton: nil
            )
            .ifLet(exploreConfirmationDialog) { view, dialog in
                view.confirmationDialog(viewModel: dialog)
            }
        } else {
            LazyVStack(spacing: .zero) {
                ForEach(transactionItems) { sectionItem in
                    sectionHeader(title: sectionItem.header)

                    ForEach(sectionItem.items) { cellItem in
                        rowOrChip(for: cellItem)
                    }
                }

                if let fetchMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.Tangem.Graphic.Neutral.primary))
                        .padding(.vertical, .unit(.x4))
                        .onAppear { fetchMore.start() }
                        .id(fetchMore.id)
                }
            }
        }
    }

    @ViewBuilder
    private func rowOrChip(for viewModel: TransactionViewModel) -> some View {
        Button {
            exploreTransactionAction(viewModel.hash)
        } label: {
            switch viewModel.display.style {
            case .chip:
                TransactionChipRedesigned(viewModel: viewModel)
                    .padding(.vertical, .unit(.x1))
            case .row:
                TransactionViewRedesigned(viewModel: viewModel)
                    .padding(.vertical, .unit(.x3))
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .style(.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.primary)

            Spacer()
        }
        .padding(.top, .unit(.x6))
        .padding(.bottom, .unit(.x3))
    }

    private var loadingContent: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< 3, id: \.self) { _ in
                TangemTwoLineRowSkeletonView()
            }
        }
    }

    private func notSupportedExploreButton(action: @escaping () -> Void) -> StatusStateView.ActionButton {
        StatusStateView.ActionButton(title: Localization.commonExploreTransactionHistory, action: action)
    }

    private func emptyExploreButton(action: @escaping () -> Void) -> StatusStateView.ActionButton {
        StatusStateView.ActionButton(title: Localization.commonExplore, action: action)
    }

    private var errorReloadButton: StatusStateView.ActionButton {
        StatusStateView.ActionButton(
            title: Localization.commonReload,
            icon: Assets.reload,
            isLoading: isReloadButtonBusy,
            action: reloadButtonAction
        )
    }

    private func errorExploreButton(action: @escaping () -> Void) -> StatusStateView.ActionButton {
        StatusStateView.ActionButton(title: Localization.commonExplore, action: action)
    }
}

// MARK: - Empty / Not-supported / Error state shell

private struct StatusStateView: View {
    struct ActionButton {
        let title: String
        let icon: ImageType
        let isLoading: Bool
        let action: () -> Void

        init(title: String, icon: ImageType = Assets.arrowRightUpMini, isLoading: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.isLoading = isLoading
            self.action = action
        }
    }

    let icon: ImageType
    let message: String
    let primaryButton: ActionButton?
    let secondaryButton: ActionButton?

    var body: some View {
        VStack(spacing: .unit(.x4)) {
            icon.image
                .renderingMode(.template)
                .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)

            Text(message)
                .multilineTextAlignment(.center)
                .style(.Tangem.Subheadline.medium, color: .Tangem.Text.Neutral.primary)
                .padding(.horizontal, .unit(.x9))

            if primaryButton != nil || secondaryButton != nil {
                HStack(spacing: .unit(.x2)) {
                    if let primaryButton {
                        actionButton(primaryButton)
                    }
                    if let secondaryButton {
                        actionButton(secondaryButton)
                    }
                }
            }
        }
        .padding(.vertical, .unit(.x6))
    }

    private func actionButton(_ button: ActionButton) -> some View {
        TangemButton(
            content: .combined(
                text: AttributedString(button.title),
                icon: button.icon,
                iconPosition: .right
            ),
            action: button.action
        )
        .setStyleType(.secondary)
        .setSize(.x10)
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.intrinsic)
        .setButtonState(isLoading: button.isLoading)
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Loaded") {
    let items = [
        TransactionListItem(
            header: "Today",
            items: TransactionView_Previews.figmaViewModels1
        ),
        TransactionListItem(
            header: "June 12, 2026",
            items: TransactionView_Previews.figmaViewModels2
        ),
    ]
    return ScrollView {
        TransactionsListViewRedesigned(
            state: .loaded(items),
            exploreAction: {},
            exploreConfirmationDialog: nil,
            exploreTransactionAction: { _ in },
            reloadButtonAction: {},
            isReloadButtonBusy: false,
            fetchMore: nil
        )
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}

#Preview("Error") {
    TransactionsListViewRedesigned(
        state: .error("oops"),
        exploreAction: {},
        exploreConfirmationDialog: nil,
        exploreTransactionAction: { _ in },
        reloadButtonAction: {},
        isReloadButtonBusy: false,
        fetchMore: nil
    )
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}

#Preview("Empty") {
    TransactionsListViewRedesigned(
        state: .loaded([]),
        exploreAction: {},
        exploreConfirmationDialog: nil,
        exploreTransactionAction: { _ in },
        reloadButtonAction: {},
        isReloadButtonBusy: false,
        fetchMore: nil
    )
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}

#endif // DEBUG
