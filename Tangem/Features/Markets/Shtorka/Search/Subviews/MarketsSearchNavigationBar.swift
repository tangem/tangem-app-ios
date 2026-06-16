//
//  MarketsSearchNavigationBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsSearchNavigationBar<Content: View>: View {
    let titleView: () -> Content
    let leadingButton: LeadingButton
    let onLeadingButtonAction: () -> Void
    let onSearchButtonAction: () -> Void

    init(
        titleView: @escaping () -> Content,
        leadingButton: LeadingButton,
        onLeadingButtonAction: @escaping () -> Void,
        onSearchButtonAction: @escaping () -> Void
    ) {
        self.titleView = titleView
        self.leadingButton = leadingButton
        self.onLeadingButtonAction = onLeadingButtonAction
        self.onSearchButtonAction = onSearchButtonAction
    }

    var body: some View {
        NavigationBar(
            settings: .init(
                backgroundColor: .clear, // Controlled by the `background` modifier in the body
                height: 64.0,
                alignment: .bottom
            ),
            titleView: titleView,
            leftButtons: {
                leftButton
            },
            rightButtons: {
                SearchButton(
                    height: 44.0,
                    isVisible: true,
                    isEnabled: true,
                    hPadding: 10.0,
                    action: onSearchButtonAction
                )
            }
        )
    }

    @ViewBuilder
    private var leftButton: some View {
        switch leadingButton {
        case .back:
            BackButton(
                height: 44.0,
                isVisible: true,
                isEnabled: true,
                hPadding: 10.0,
                action: onLeadingButtonAction
            )
        case .close:
            OnboardingCloseButton(
                height: 44.0,
                hPadding: 16.0,
                action: onLeadingButtonAction
            )
        }
    }
}

extension MarketsSearchNavigationBar {
    enum LeadingButton {
        case back
        case close
    }
}

extension MarketsSearchNavigationBar where Content == DefaultNavigationBarTitle {
    init(
        title: String,
        leadingButton: LeadingButton,
        onLeadingButtonAction: @escaping () -> Void,
        onSearchButtonAction: @escaping () -> Void
    ) {
        let font: Font
        let color: Color

        if FeatureProvider.isAvailable(.redesign) {
            font = Font.Tangem.Body16.semibold.font // [REDACTED_INFO]: tracking deferred
            color = Color.Tangem.Text.Neutral.primary
        } else {
            font = Fonts.Bold.body
            color = Colors.Text.primary1
        }

        titleView = {
            DefaultNavigationBarTitle(
                title,
                settings: .init(
                    font: font,
                    color: color,
                    lineLimit: 1,
                    minimumScaleFactor: 0.6
                )
            )
        }
        self.leadingButton = leadingButton
        self.onLeadingButtonAction = onLeadingButtonAction
        self.onSearchButtonAction = onSearchButtonAction
    }
}

#if DEBUG
#Preview {
    MarketsSearchNavigationBar(
        title: "Market",
        leadingButton: .back,
        onLeadingButtonAction: {},
        onSearchButtonAction: {}
    )
}
#endif
