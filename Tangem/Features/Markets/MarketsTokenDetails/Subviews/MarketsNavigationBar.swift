//
//  MarketsNavigationBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsNavigationBar<Content: View, RightButtons: View>: View {
    let titleView: () -> Content
    let onBackButtonAction: () -> Void
    let rightButtons: () -> RightButtons

    init(
        titleView: @escaping () -> Content,
        onBackButtonAction: @escaping () -> Void,
        @ViewBuilder rightButtons: @escaping () -> RightButtons
    ) {
        self.titleView = titleView
        self.onBackButtonAction = onBackButtonAction
        self.rightButtons = rightButtons
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
            rightButtons: rightButtons
        )
    }
}

extension MarketsNavigationBar where RightButtons == EmptyView {
    init(titleView: @escaping () -> Content, onBackButtonAction: @escaping () -> Void) {
        self.titleView = titleView
        self.onBackButtonAction = onBackButtonAction
        rightButtons = { EmptyView() }
    }
}

extension MarketsNavigationBar where Content == DefaultNavigationBarTitle, RightButtons == EmptyView {
    init(title: String, onBackButtonAction: @escaping () -> Void) {
        titleView = {
            DefaultNavigationBarTitle(
                title,
                settings: .init(
                    font: Fonts.Bold.body,
                    color: Colors.Text.primary1,
                    lineLimit: 1,
                    minimumScaleFactor: 0.6
                )
            )
        }
        self.onBackButtonAction = onBackButtonAction
        rightButtons = { EmptyView() }
    }
}

#Preview {
    MarketsNavigationBar(
        title: "Exchanges",
        onBackButtonAction: {}
    )
}
