//
//  TokenDetailsBalanceStateView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokenDetailsBalanceStateView: View {
    let state: TokenDetailsBalanceState
    let skeletonSize: CGSize
    let token: TangemTypographyToken
    let color: Color
    var minimumScaleFactor: CGFloat = 1

    @ObservedObject private var visibilityState = SensitiveTextVisibilityState.shared

    var body: some View {
        switch state {
        case .loaded(let text):
            textView(text)

        case .loadingCached(let text):
            textView(text)
                .shimmering()

        case .loading:
            skeletonView(size: skeletonSize)

        case .failed(let text):
            textView(text)
        }
    }
}

// MARK: - Subviews

private extension TokenDetailsBalanceStateView {
    func textView(_ text: TokenDetailsBalanceState.Text) -> some View {
        UtilBalance(text)
            .masked(visibilityState.isHidden)
            .style(token, color: color)
            .minimumScaleFactor(minimumScaleFactor)
            .modifier(CountsDownTransitionModifier(text: text))
    }

    func skeletonView(size: CGSize) -> some View {
        Shimmer()
            .variant(.custom(cornerRadius: size.height / 2))
            .frame(size: size)
    }
}

// MARK: - CountsDownTransitionModifier

private struct CountsDownTransitionModifier: ViewModifier {
    let text: TokenDetailsBalanceState.Text

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .contentTransition(.numericText(countsDown: false))
                .animation(.default, value: text)
        } else {
            content
        }
    }
}
