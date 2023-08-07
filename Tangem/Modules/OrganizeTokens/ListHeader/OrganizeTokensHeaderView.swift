//
//  OrganizeTokensHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensHeaderView: View {
    @ObservedObject var viewModel: OrganizeTokensHeaderViewModel

    var body: some View {
        let shadowOpacity = 0.1
        let toggledShadowOpacity = shadowOpacity / (viewModel.isSortByBalanceEnabled ? 3.0 : 1.0)

        HStack(spacing: 8.0) {
            Group {
                FlexySizeButtonWithLeadingIcon(
                    title: viewModel.sortByBalanceButtonTitle,
                    icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                    isToggled: viewModel.isSortByBalanceEnabled,
                    action: viewModel.toggleSortState
                )
                // [REDACTED_TODO_COMMENT]
                .shadow(color: Colors.Button.primary.opacity(toggledShadowOpacity), radius: 5.0)

                FlexySizeButtonWithLeadingIcon(
                    title: viewModel.groupingButtonTitle,
                    icon: Assets.OrganizeTokens.makeGroupIcon.image,
                    action: viewModel.toggleGroupState
                )
                // [REDACTED_TODO_COMMENT]
                .shadow(color: Colors.Button.primary.opacity(shadowOpacity), radius: 5.0)
            }
            .background(
                Colors.Background
                    .primary
                    .cornerRadiusContinuous(10.0)
            )
            .onFirstAppear(perform: viewModel.onViewAppear)
        }
    }
}

// MARK: - Previews

struct OrganizeTokensHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let optionsManager = OrganizeTokensOptionsManagerStub()
        let viewModel = OrganizeTokensHeaderViewModel(
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )
        return OrganizeTokensHeaderView(viewModel: viewModel)
    }
}
