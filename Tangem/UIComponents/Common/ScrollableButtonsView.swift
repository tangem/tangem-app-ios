//
//  ScrollableButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct ScrollableButtonsView: View {
    /// Use this properties to expand scroll view beyond parent view
    /// This is usefull when your parent view has paddings, but scroll must
    /// go to the edge of the scree
    let itemsHorizontalOffset: CGFloat
    let itemsVerticalOffset: CGFloat
    let buttonsInfo: [FixedSizeButtonWithIconInfo]

    init(itemsHorizontalOffset: CGFloat, itemsVerticalOffset: CGFloat = 0, buttonsInfo: [FixedSizeButtonWithIconInfo]) {
        self.itemsHorizontalOffset = itemsHorizontalOffset
        self.itemsVerticalOffset = itemsVerticalOffset
        self.buttonsInfo = buttonsInfo
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(buttonsInfo) { button in
                    FixedSizeButtonWithLeadingIcon(
                        title: button.title,
                        icon: button.icon.image,
                        loading: button.loading,
                        style: button.style,
                        action: button.action,
                        longPressAction: button.longPressAction
                    )
                    .allowsHitTesting(!button.loading)
                    .disabled(button.disabled)
                    .unreadNotificationBadge(button.shouldShowBadge, badgeColor: Colors.Icon.accent)
                    .accessibilityIdentifier(button.accessibilityIdentifier)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(TokenAccessibilityIdentifiers.actionButtonsList)
            .padding(.horizontal, itemsHorizontalOffset)
            .padding(.vertical, itemsVerticalOffset)
        }
        .padding(.horizontal, -itemsHorizontalOffset)
        .padding(.vertical, -itemsVerticalOffset)
    }
}

struct ScrollableButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ScrollableButtonsView(
                itemsHorizontalOffset: 16,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, disabled: true, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, disabled: true, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Receive", icon: Assets.arrowDownMini, disabled: true, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Exchange", icon: Assets.exchangeMini, disabled: false, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Organize tokens", icon: Assets.sliders, disabled: false, action: {}),
                    FixedSizeButtonWithIconInfo(title: "", icon: Assets.horizontalDots, disabled: true, action: {}),
                ]
            )

            ScrollableButtonsView(
                itemsHorizontalOffset: 0,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Receive", icon: Assets.arrowDownMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Exchange", icon: Assets.exchangeMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Organize tokens", icon: Assets.sliders, action: {}),
                    FixedSizeButtonWithIconInfo(title: "", icon: Assets.horizontalDots, action: {}),
                ]
            )

            ScrollableButtonsView(
                itemsHorizontalOffset: 0,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(title: "Buy", icon: Assets.plusMini, action: {}),
                    FixedSizeButtonWithIconInfo(title: "Send", icon: Assets.arrowUpMini, action: {}),
                ]
            )
        }
        .padding(.horizontal, 16)
    }
}
