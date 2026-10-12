//
//  TransactionsListViewRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TransactionsListViewRedesigned: View {
    let state: TransactionsListView.State
    let exploreAction: (() -> Void)?
    let openTransactionDetailsAction: (TransactionViewModel) -> Void
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
        } else {
            // The section is inlined instead of extracted into a view of its own on purpose:
            // a custom view is opaque to the lazy stack, so it would build every row of a section at once.
            LazyVStack(spacing: .zero) {
                ForEach(transactionItems.indexed(), id: \.1.id) { _, sectionItem in
                    if sectionItem.header.isNotEmpty {
                        TransactionsListSectionHeaderView(title: sectionItem.header)
                    }

                    ForEach(sectionItem.items, id: \.self) { cellItem in
                        TransactionsListRowView(
                            viewModel: cellItem,
                            openTransactionDetailsAction: openTransactionDetailsAction
                        )
                    }
                }

                if let fetchMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Color.iconPrimary))
                        .padding(.vertical, 16)
                        .onAppear { fetchMore.start() }
                        .id(fetchMore.id)
                }
            }
        }
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
        VStack(spacing: 16) {
            icon.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.statusStateIcon)

            Text(message)
                .multilineTextAlignment(.center)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)

            if primaryButton != nil || secondaryButton != nil {
                HStack(spacing: 8) {
                    if let primaryButton {
                        actionButton(primaryButton)
                    }
                    if let secondaryButton {
                        actionButton(secondaryButton)
                    }
                }
            }
        }
        .padding(.vertical, 24)
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
            items: TransactionViewPreviewData.figmaViewModels1
        ),
        TransactionListItem(
            header: "June 12, 2026",
            items: TransactionViewPreviewData.figmaViewModels2
        ),
    ]
    return ScrollView {
        TransactionsListViewRedesigned(
            state: .loaded(items),
            exploreAction: {},
            openTransactionDetailsAction: { _ in },
            reloadButtonAction: {},
            isReloadButtonBusy: false,
            fetchMore: nil
        )
    }
    .background(DesignSystem.Color.bgPrimary.edgesIgnoringSafeArea(.all))
}

#Preview("Error") {
    TransactionsListViewRedesigned(
        state: .error("oops"),
        exploreAction: {},
        openTransactionDetailsAction: { _ in },
        reloadButtonAction: {},
        isReloadButtonBusy: false,
        fetchMore: nil
    )
    .background(DesignSystem.Color.bgPrimary.edgesIgnoringSafeArea(.all))
}

#Preview("Empty") {
    TransactionsListViewRedesigned(
        state: .loaded([]),
        exploreAction: {},
        openTransactionDetailsAction: { _ in },
        reloadButtonAction: {},
        isReloadButtonBusy: false,
        fetchMore: nil
    )
    .background(DesignSystem.Color.bgPrimary.edgesIgnoringSafeArea(.all))
}
#endif // DEBUG
