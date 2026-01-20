//
//  ArchivedAccountRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccounts

struct ArchivedAccountRowView: View {
    let viewData: ViewData

    var body: some View {
        AccountIconWithContentView(
            iconData: viewData.iconData,
            name: viewData.name,
            subtitle: { Text(viewData.subtitle) },
            trailing: {
                CapsuleButton(title: Localization.accountArchivedRecover, action: viewData.onRecover)
                    .loading(viewData.isRecovering)
                    .disabled(viewData.isRecoverDisabled)
                    .lineLimit(1)
            }
        )
    }
}

// MARK: - ViewData

extension ArchivedAccountRowView {
    struct ViewData {
        let iconData: AccountIconView.ViewData
        let name: String
        let subtitle: String
        let isRecovering: Bool
        let isRecoverDisabled: Bool
        let onRecover: () -> Void
    }
}
