//
//  OrganizeTokensListOuterSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccounts

struct OrganizeTokensListOuterSectionView: View {
    let title: String
    let iconData: AccountIconView.ViewData

    var body: some View {
        AccountIconWithContentView(iconData: iconData, name: title)
            .iconSettings(.smallSized)
            .style(Fonts.BoldStatic.caption1.weight(.medium), color: Colors.Text.primary1)
            .padding(.horizontal, 14.0)
            .padding(.top, 14.0)
            .padding(.bottom, 6.0)
    }
}
