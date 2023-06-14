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
        HStack(spacing: 8.0) {
            Group {
                Group {
                    if viewModel.isSortByBalanceEnabled {
                        FlexySizeSelectedButtonWithLeadingIcon(
                            title: viewModel.sortByBalanceButtonTitle,
                            icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                            action: viewModel.toggleSortState
                        )
                    } else {
                        FlexySizeDeselectedButtonWithLeadingIcon(
                            title: viewModel.sortByBalanceButtonTitle,
                            icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                            action: viewModel.toggleSortState
                        )
                    }
                }
                .transition(.opacity.animation(.default))

                FlexySizeSelectedButtonWithLeadingIcon(
                    title: viewModel.groupingButtonTitle,
                    icon: Assets.OrganizeTokens.makeGroupIcon.image,
                    action: viewModel.toggleGroupState
                )
            }
            .background(
                Colors.Background
                    .primary
                    .cornerRadiusContinuous(10.0)
            )
        }
    }
}

// MARK: - Previews

struct OrganizeTokensHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        OrganizeTokensHeaderView(
            viewModel: .init()
        )
    }
}
