//
//  TangemPayMoneyAccountContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayMoneyAccountContentView: View {
    let state: TangemPayMoneyAccountStateModel
    let refreshScrollState: RefreshScrollViewStateObject
    let action: (TangemPayMoneyAccountAction) -> Void

    @StateObject private var elasticContainerModel: TangemElasticContainerModel
    @State private var headerHeightRatio: CGFloat = 1
    @State private var visibleBodyHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0

    init(
        state: TangemPayMoneyAccountStateModel,
        refreshScrollState: RefreshScrollViewStateObject,
        action: @escaping (TangemPayMoneyAccountAction) -> Void
    ) {
        self.state = state
        self.refreshScrollState = refreshScrollState
        self.action = action
        _elasticContainerModel = StateObject(
            wrappedValue: TangemElasticContainerModel(
                scrollViewInteractor: refreshScrollState.scrollViewInteractor
            )
        )
    }

    var body: some View {
        RefreshScrollView(
            stateObject: refreshScrollState,
            contentSettings: .simpleContent
        ) {
            VStack(spacing: 0) {
                TangemElasticContainer(
                    viewModel: elasticContainerModel,
                    content: collapsingHeader
                )
                .opacity(headerOpacity)
                .animation(.default, value: headerHeightRatio)
                .readGeometry(\.size.height, bindTo: $headerHeight)

                transactionList
            }
            .padding(.horizontal, 16)
            .padding(.top, Constants.contentTopPadding)
            .animation(.default, value: isBalanceFailed)
        }
        .background {
            DesignSystem.Color.bgPrimary
                .ignoresSafeArea()
        }
        .onReceive(elasticContainerModel.heightRatioPublisher) {
            headerHeightRatio = $0
        }
        .onReceive(refreshScrollState.scrollViewInteractor.$visibleBodyHeight) {
            visibleBodyHeight = $0
        }
        .redesigned()
    }

    private var headerOpacity: CGFloat {
        clamp(2 * headerHeightRatio - 1, min: 0, max: 1)
    }

    private var isBalanceFailed: Bool {
        state.balance.isFailed
    }
}

// MARK: - Header

private extension TangemPayMoneyAccountContentView {
    var collapsingHeader: some View {
        VStack(spacing: 24) {
            header

            banners
        }
        .padding(.bottom, 8)
    }

    var header: some View {
        VStack(spacing: 64) {
            balance

            actionButtons
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
    }

    var balance: some View {
        VStack(spacing: 10) {
            TangemPayBalanceView(state: balanceState)

            Text(Localization.tokenDetailsBalanceTotal)
                .font(token: DesignSystem.Font.captionMediumToken)
                .foregroundStyle(DesignSystem.Color.textSecondary)
        }
        .opacity(isBalanceFailed ? Constants.failedBalanceOpacity : 1)
    }

    var balanceState: LoadableBalanceView.State {
        switch state.balance {
        case .loading(let cached):
            .loading(cached: .string(cached))
        case .loaded(let balance):
            .loaded(text: balance)
        case .failed(let cached):
            .failed(cached: .string(cached))
        }
    }

    var actionButtons: some View {
        HStack(alignment: .top, spacing: 40) {
            TangemMainActionButton(
                title: Localization.tangempayCardDetailsAddFunds,
                icon: DesignSystem.Icons.ArrowDown.regular16,
                action: { action(.topup) }
            )

            TangemMainActionButton(
                title: Localization.commonSend,
                icon: DesignSystem.Icons.ArrowUp.regular16,
                action: { action(.withdraw) }
            )
        }
        .disabled(isBalanceFailed)
    }
}

// MARK: - Banners

private extension TangemPayMoneyAccountContentView {
    var banners: some View {
        VStack(spacing: 8) {
            if isBalanceFailed {
                TangemPayMoneyAccountBalanceUnavailableBannerView()
            }

            // [REDACTED_TODO_COMMENT]
        }
    }
}

// MARK: - Transaction list

private extension TangemPayMoneyAccountContentView {
    var transactionList: some View {
        TransactionsListViewRedesigned(
            state: state.transactionHistory,
            exploreAction: { action(.openExplorer) },
            openTransactionDetailsAction: { action(.openTransactionDetails(id: $0.id)) },
            reloadButtonAction: { action(.reloadTransactionHistory) },
            isReloadButtonBusy: state.isTrxHistoryReloading,
            // [REDACTED_TODO_COMMENT]
            fetchMore: nil
        )
        .frame(maxWidth: .infinity, minHeight: placeholderHeight)
        .frame(maxWidth: .infinity, minHeight: visibleBodyHeight, alignment: .top)
    }

    var placeholderHeight: CGFloat? {
        guard state.transactionHistory.isPlaceholder else {
            return nil
        }

        return max(0, visibleBodyHeight - Constants.contentTopPadding - headerHeight)
    }
}

private extension TransactionsListView.State {
    var isPlaceholder: Bool {
        switch self {
        case .notSupported, .error: true
        case .loaded(let sections): sections.isEmpty
        case .loading: false
        }
    }
}

// MARK: - Constants

private extension TangemPayMoneyAccountContentView {
    enum Constants {
        static let contentTopPadding: CGFloat = 12
        static let failedBalanceOpacity: CGFloat = 0.5
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Idle") {
    TangemPayMoneyAccountContentPreview(
        state: TangemPayMoneyAccountStateModel(
            balance: .loaded("$1250,50"),
            transactionHistory: .loaded(TangemPayMoneyAccountPreviewData.transactions)
        )
    )
}

#Preview("Balance failed") {
    TangemPayMoneyAccountContentPreview(
        state: TangemPayMoneyAccountStateModel(
            balance: .failed(cached: "$2250,50"),
            transactionHistory: .loaded(TangemPayMoneyAccountPreviewData.transactions)
        )
    )
}

#Preview("History failed") {
    TangemPayMoneyAccountContentPreview(
        state: TangemPayMoneyAccountStateModel(
            balance: .loaded("$0,00"),
            transactionHistory: .error("Preview")
        )
    )
}

#Preview("Empty") {
    TangemPayMoneyAccountContentPreview(
        state: TangemPayMoneyAccountStateModel(
            balance: .loaded("$0,00"),
            transactionHistory: .loaded([])
        )
    )
}

#Preview("Loading") {
    TangemPayMoneyAccountContentPreview(
        state: TangemPayMoneyAccountStateModel(
            balance: .loading(cached: "$0,00"),
            transactionHistory: .loading
        )
    )
}
#endif // DEBUG
