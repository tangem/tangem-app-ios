//
//  TokenSelectorExpandableAccountSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts
import TangemUIUtils

struct TokenSelectorExpandableAccountSectionView: View {
    @ObservedObject var expandableViewModel: TokenSelectorExpandableAccountItemViewModel
    @ObservedObject var accountViewModel: AccountsAwareTokenSelectorAccountViewModel

    @Namespace private var namespace

    var body: some View {
        let effects = AccountGeometryEffects(namespace: namespace)

        return ExpandableItemView(
            isExpanded: expandableViewModel.isExpanded,
            backgroundColor: Colors.Background.action,
            cornerRadius: Constants.cornerRadius,
            backgroundGeometryEffect: effects.background,
            expandedViewTransition: Constants.expandedContentTransition,
            collapsedView: {
                CollapsedAccountItemHeaderView(
                    name: expandableViewModel.name,
                    iconData: expandableViewModel.iconData,
                    tokensCount: expandableViewModel.tokensCount,
                    totalFiatBalance: expandableViewModel.totalFiatBalance,
                    priceChange: expandableViewModel.priceChange,
                    iconGeometryEffect: effects.icon,
                    iconBackgroundGeometryEffect: effects.iconBackground,
                    nameGeometryEffect: effects.name,
                    tokensCountGeometryEffect: effects.tokensCount,
                    balanceGeometryEffect: effects.balance
                )
            },
            expandedView: {
                expandedContent
            },
            expandedViewHeader: {
                ExpandedAccountItemHeaderView(
                    name: expandableViewModel.name,
                    iconData: expandableViewModel.iconData,
                    totalFiatBalance: expandableViewModel.totalFiatBalance,
                    iconGeometryEffect: effects.icon,
                    iconBackgroundGeometryEffect: effects.iconBackground,
                    nameGeometryEffect: effects.name,
                    tokensCountGeometryEffect: effects.tokensCount,
                    balanceGeometryEffect: effects.balance
                )
            },
            onExpandedChange: expandableViewModel.onExpandedChange
        )
        .onAppear(perform: expandableViewModel.onViewAppear)
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            ForEach(accountViewModel.items) { item in
                AccountsAwareTokenSelectorItemView(viewModel: item)
                    .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)

                if accountViewModel.items.last?.id != item.id {
                    Separator(height: .minimal, color: Colors.Stroke.primary)
                        .padding(.horizontal, GroupedSectionConstants.defaultHorizontalPadding)
                }
            }
        }
    }
}

// MARK: - Constants

private extension TokenSelectorExpandableAccountSectionView {
    enum Constants {
        static let cornerRadius: CGFloat = GroupedSectionConstants.defaultCornerRadius

        static var expandedContentTransition: AnyTransition {
            .asymmetric(
                insertion: .offset(y: 20).combined(with: .opacity),
                removal: .opacity
            )
        }
    }
}
