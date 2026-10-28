//
//  TangemPayMoneyAccountRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayMoneyAccountRowView: View {
    let onTap: () -> Void

    var body: some View {
        Row(
            title: Localization.moneyAccountMainName,
            subtitle: Localization.moneyAccountMainStatusActivating
        )
        .start { avatar }
        .onTap(action: onTap)
        .background(
            DesignSystem.Color.bgSecondary,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var avatar: some View {
        Avatar(
            .account(DesignSystem.Icons.accountSafe, fill: Colors.Accounts.vitalGreen),
            size: .size40
        )
    }
}

// MARK: - Previews

#Preview {
    TangemPayMoneyAccountRowView(onTap: {})
        .padding(.horizontal, 12)
}
