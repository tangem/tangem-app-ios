//
//  TransferInputErrorBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemLocalization

struct TransferInputErrorBanner: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: Constants.spacing) {
            VStack(spacing: 4) {
                HStack(spacing: 12) {
                    // [REDACTED_TODO_COMMENT]
                    Text("Network fee info unreachable")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Spacer()

                    DesignSystem.Icons.Error.regular20.image
                        .renderingMode(.template)
                        .foregroundStyle(DesignSystem.Color.iconPrimary)
                }

                // [REDACTED_TODO_COMMENT]
                Text("Check your network connection")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TangemUI.Button(
                label: Localization.warningButtonRefresh,
                accessibilityLabel: nil,
                action: action
            )
            .size(.x12)
            .styleType(.secondary(.default))
            .horizontalLayout(.infinity)
        }
        .padding(Constants.padding)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        .glowRing(.error, cornerRadius: Constants.cornerRadius)
    }
}

// MARK: - Constants

private extension TransferInputErrorBanner {
    enum Constants {
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 28
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TransferInputErrorBanner(action: {})
        .padding(16)
}
#endif
