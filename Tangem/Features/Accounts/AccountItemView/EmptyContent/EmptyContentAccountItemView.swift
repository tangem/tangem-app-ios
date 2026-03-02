//
//  EmptyContentAccountItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI
import TangemLocalization

struct EmptyContentAccountItemView: View {
    let onManageTokensTap: () -> Void

    var body: some View {
        VStack(spacing: 20.0) {
            MultiWalletTokenItemsEmptyView()

            CapsuleButton(title: Localization.mainManageTokens, action: onManageTokensTap)
                .style(.secondary)
                .size(.medium)
        }
        .padding(.vertical, 24.0)
    }
}
