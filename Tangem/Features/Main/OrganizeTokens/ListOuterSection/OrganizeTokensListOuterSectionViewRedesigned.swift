//
//  OrganizeTokensListOuterSectionViewRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccounts
import TangemAccessibilityIdentifiers
import TangemUI

struct OrganizeTokensListOuterSectionViewRedesigned: View {
    let title: String
    let iconData: AccountIconView.ViewData
    let outerSectionIndex: Int
    let accountId: AnyHashable

    @ScaledMetric private var horizontalPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var verticalPadding: CGFloat = .unit(.x2)

    var body: some View {
        AccountIconWithContentView(iconData: iconData, name: title)
            .iconSettings(.smallSized)
            .nameStyle(font: Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .accessibilityIdentifier(
                OrganizeTokensAccessibilityIdentifiers.accountHeader(
                    outerSection: outerSectionIndex,
                    accountId: accountId,
                    accountName: title
                )
            )
    }
}
