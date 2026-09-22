//
//  JointAccountInviteLoadFailedView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct JointAccountInviteLoadFailedView: View {
    let isRetrying: Bool
    let onCloseTap: () -> Void
    let onRetryTap: () -> Void

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: Constants.spacing) {
                TangemUI.Button(
                    icon: DesignSystem.Icons.ArrowRefresh.regular20,
                    accessibilityLabel: Localization.commonReload,
                    action: onRetryTap
                )
                .styleType(.default)
                .size(.x10)
                .loading(.spinner(if: isRetrying))

                Text(Localization.jointAccountInviteLoadFailedSubtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .topNavigation(leading: .none, onClose: onCloseTap)
    }
}

// MARK: - Constants

private extension JointAccountInviteLoadFailedView {
    enum Constants {
        static let spacing: CGFloat = 12
    }
}

// MARK: - Previews

#Preview {
    JointAccountInviteLoadFailedView(isRetrying: false, onCloseTap: {}, onRetryTap: {})
}
