//
//  JointAccountInvalidInviteView.swift
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

struct JointAccountInvalidInviteView: View {
    let onCloseTap: () -> Void
    let onGotItTap: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Color.bgPrimary.ignoresSafeArea()

            JointAccountIconMessage(
                icon: DesignSystem.Icons.Warning.filled28,
                iconColor: DesignSystem.Color.iconStatusWarning,
                iconBackgroundColor: DesignSystem.Color.bgStatusWarningSubtle,
                title: Localization.jointAccountInviteInvalidTitle,
                message: Localization.jointAccountInviteInvalidSubtitle
            )
            .infinityFrame()
        }
        .topNavigation(leading: .none, onClose: onCloseTap)
        .safeAreaInset(edge: .bottom) { footer }
    }

    private var footer: some View {
        TangemUI.Button(
            label: Localization.commonGotIt,
            accessibilityLabel: Localization.commonGotIt,
            action: onGotItTap
        )
        .styleType(.default)
        .horizontalLayout(.infinity)
        .size(.x12)
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.bottom, Constants.footerBottomPadding)
    }
}

// MARK: - Constants

private extension JointAccountInvalidInviteView {
    enum Constants {
        static let footerHorizontalPadding: CGFloat = 16
        static let footerBottomPadding: CGFloat = 12
    }
}

// MARK: - Previews

#Preview {
    JointAccountInvalidInviteView(onCloseTap: {}, onGotItTap: {})
}
