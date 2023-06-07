//
//  OrganizeTokensHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensHeaderView: View {
    var body: some View {
        HStack(spacing: 8.0) {
            ButtonWithLeadingIcon(
                title: Localization.organizeTokensSortByBalance,
                icon: Assets.OrganizeTokens.byBalanceSortIcon.image,
                foregroundColor: Colors.Text.primary1,  // [REDACTED_TODO_COMMENT]
                maintainsIdealSize: false
            ) {}

            ButtonWithLeadingIcon(
                title: Localization.organizeTokensGroup,
                icon: Assets.OrganizeTokens.makeGroupIcon.image,
                foregroundColor: Colors.Text.primary1,  // [REDACTED_TODO_COMMENT]
                maintainsIdealSize: false
            ) {}
        }
    }
}

// MARK: - Previews

struct OrganizeTokensHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        OrganizeTokensHeaderView()
    }
}
