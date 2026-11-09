//
//  SendTokenHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccounts
import TangemLocalization

struct SendTokenHeaderView: View {
    let header: SendTokenHeader

    var body: some View {
        switch header {
        case .action(let name):
            Text(.init(name))
                .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)
        case .wallet(let name):
            Text(.init(name))
                .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)
        case .account(let prefix, let name, let icon):
            HStack(spacing: 6) {
                Text(.init(prefix))
                    .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)

                HStack(spacing: 4) {
                    AccountIconView(data: icon)
                        .settings(.smallSized)

                    Text(name)
                        .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)
                }
            }
        }
    }
}
