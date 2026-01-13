//
//  ExpandedAccountItemHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemAccounts

struct ExpandedAccountItemHeaderView: View {
    let name: String
    let iconData: AccountIconView.ViewData

    var body: some View {
        HStack(spacing: .zero) {
            AccountInlineHeaderView(iconData: iconData, name: name)
                .iconSettings(.smallSized)
                .font(Fonts.BoldStatic.caption1)

            Spacer()

            Assets.Accounts.minimize.image
        }
        .padding(.horizontal, 14.0)
        .padding(.top, 14.0)
        // There is an additional padding of 6.0 pt somewhere in the view hierarchy,
        // there is why we use 2.0 pt here to make total 8.0 pt to match the mockup
        .padding(.bottom, 2.0)
    }
}
