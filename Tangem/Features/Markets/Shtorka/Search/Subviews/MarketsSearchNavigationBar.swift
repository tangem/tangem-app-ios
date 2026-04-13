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
    let onBackButtonAction: () -> Void
    let onSearchButtonAction: () -> Void

    init(
        titleView: @escaping () -> Content,
        onBackButtonAction: @escaping () -> Void,
        onSearchButtonAction: @escaping () -> Void
    ) {
        self.titleView = titleView
        self.onBackButtonAction = onBackButtonAction
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
                BackButton(
                    height: 44.0,
                    isVisible: true,
                    isEnabled: true,
                    hPadding: 10.0,
                    action: onBackButtonAction
                )
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
}

extension MarketsSearchNavigationBar where Content == DefaultNavigationBarTitle {
    init(title: String, onBackButtonAction: @escaping () -> Void, onSearchButtonAction: @escaping () -> Void) {
        let font: Font
        let color: Color

        if FeatureProvider.isAvailable(.redesign) {
            font = Font.Tangem.Body16.semibold
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
        self.onBackButtonAction = onBackButtonAction
        self.onSearchButtonAction = onSearchButtonAction
    }
}

#if DEBUG
#Preview {
    MarketsSearchNavigationBar(
        title: "Market",
        onBackButtonAction: {},
        onSearchButtonAction: {}
    )
}
#endif
