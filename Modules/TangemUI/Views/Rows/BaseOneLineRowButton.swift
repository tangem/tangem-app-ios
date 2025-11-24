//
//  BaseOneLineRowButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct BaseOneLineRowButton<SecondLeadingView: View, TitleView: View, TrailingView: View>: View {
    private let icon: ImageType?
    private let shouldShowTrailingIcon: Bool
    private let action: () -> Void
    private let titleView: TitleView
    private let secondLeadingView: () -> SecondLeadingView
    private let trailingView: () -> TrailingView

    private var verticalPadding: CGFloat = 0

    public var body: some View {
        Button(action: action) {
            content
                .padding(.vertical, verticalPadding)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        BaseOneLineRow(
            icon: icon,
            titleView: { titleView },
            secondLeadingView: secondLeadingView,
            trailingView: trailingView
        )
        .shouldShowTrailingIcon(shouldShowTrailingIcon)
    }
}

extension BaseOneLineRowButton: Setupable {
    public func verticalPadding(_ value: CGFloat) -> Self {
        map { $0.verticalPadding = value }
    }
}

public extension BaseOneLineRowButton {
    init(
        icon: ImageType?,
        title: String,
        shouldShowTrailingIcon: Bool,
        action: @escaping () -> Void,
        @ViewBuilder secondLeadingView: @escaping () -> SecondLeadingView = EmptyView.init,
        @ViewBuilder trailingView: @escaping () -> TrailingView
    ) where TitleView == BaseOneLineRowDefaultTitleView {
        self.icon = icon
        self.action = action
        self.shouldShowTrailingIcon = shouldShowTrailingIcon
        titleView = BaseOneLineRowDefaultTitleView(title: title)
        self.secondLeadingView = secondLeadingView
        self.trailingView = trailingView
    }

    init(
        icon: ImageType?,
        shouldShowTrailingIcon: Bool,
        action: @escaping () -> Void,
        @ViewBuilder titleView: @escaping () -> TitleView,
        @ViewBuilder secondLeadingView: @escaping () -> SecondLeadingView = EmptyView.init,
        @ViewBuilder trailingView: @escaping () -> TrailingView
    ) {
        self.icon = icon
        self.action = action
        self.shouldShowTrailingIcon = shouldShowTrailingIcon
        self.titleView = titleView()
        self.secondLeadingView = secondLeadingView
        self.trailingView = trailingView
    }
}
