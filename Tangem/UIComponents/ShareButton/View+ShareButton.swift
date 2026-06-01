//
//  View+ShareButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

extension View {
    /// Wraps content in a ScrollView with a Share button at the bottom.
    /// Sheet height adapts to content size automatically.
    func withShareButton(
        backgroundColor: Color = Colors.Background.tertiary,
        topPadding: CGFloat = 30,
        shareText: @escaping () -> String
    ) -> some View {
        modifier(
            ShareButtonModifier(
                backgroundColor: backgroundColor,
                topPadding: topPadding,
                shareText: shareText
            )
        )
    }
}

private struct ShareButtonModifier: ViewModifier {
    let backgroundColor: Color
    let topPadding: CGFloat
    let shareText: () -> String

    @State private var contentHeight: CGFloat = 0

    private let buttonAreaHeight: CGFloat = MainButton.Size.default.height + 8
    private let dragIndicatorHeight: CGFloat = 20

    private var totalHeight: CGFloat {
        contentHeight + buttonAreaHeight + dragIndicatorHeight
    }

    func body(content: Content) -> some View {
        ScrollView {
            content
                .padding(.top, topPadding)
                .readGeometry(\.size.height) { contentHeight = $0 }
        }
        .background(backgroundColor)
        .safeAreaInset(edge: .bottom) {
            MainButton(
                title: Localization.commonShare,
                icon: .leading(Assets.share),
                style: .secondary,
                action: share
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .presentationDetents([.height(totalHeight)])
        .presentationDragIndicator(.visible)
    }
}

private extension ShareButtonModifier {
    @MainActor
    func share() {
        let text = shareText()
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        AppPresenter.shared.show(activityVC)
    }
}
