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
            if viewModel.isLeadingButtonSelected {
                FlexySizeSelectedButtonWithLeadingIcon(
                    title: viewModel.leadingButtonTitle,
                    icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                    action: viewModel.onLeadingButtonTap
                )
            } else {
                FlexySizeDeselectedButtonWithLeadingIcon(
                    title: viewModel.leadingButtonTitle,
                    icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                    action: viewModel.onLeadingButtonTap
                )
            }

            FlexySizeSelectedButtonWithLeadingIcon(
                title: viewModel.trailingButtonTitle,
                icon: Assets.OrganizeTokens.makeGroupIcon.image,
                action: viewModel.onTrailingButtonTap
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
