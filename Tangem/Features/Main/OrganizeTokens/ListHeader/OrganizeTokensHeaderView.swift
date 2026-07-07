//
//  OrganizeTokensHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct OrganizeTokensHeaderView: View {
    @ObservedObject var viewModel: OrganizeTokensHeaderViewModel

    var body: some View {
        HStack(spacing: 8.0) {
            FlexySizeButtonWithLeadingIcon(
                title: viewModel.sortByBalanceButtonTitle,
                icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                isToggled: viewModel.isSortByBalanceEnabled,
                action: viewModel.toggleSortState
            )
            .overrideBackgroundColor(Colors.Background.action)
            .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.sortByBalanceButton)

            FlexySizeButtonWithLeadingIcon(
                title: viewModel.groupingButtonTitle,
                icon: Assets.OrganizeTokens.makeGroupIcon.image,
                action: viewModel.toggleGroupState
            )
            .overrideBackgroundColor(Colors.Background.action)
            .accessibilityIdentifier(OrganizeTokensAccessibilityIdentifiers.groupButton)
        }
    }
}

// MARK: - Previews

#Preview {
    let optionsManager = FakeOrganizeTokensOptionsManager(
        initialGroupingOption: .none,
        initialSortingOption: .dragAndDrop
    )
    let viewModel = OrganizeTokensHeaderViewModel(
        optionsProviding: optionsManager,
        optionsEditing: optionsManager,
        analyticsLogger: TokensManagementAnalyticsLogger()
    )
    return OrganizeTokensHeaderView(viewModel: viewModel)
}
