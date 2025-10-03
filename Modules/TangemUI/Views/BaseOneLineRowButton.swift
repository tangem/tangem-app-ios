//
//  BaseOneLineRowButton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct BaseOneLineRowButton<SecondLeadingView: View, TrailingView: View>: View {
    private let icon: ImageType
    private let title: String
    private let shouldShowTrailingIcon: Bool
    private let action: () -> Void
    private let secondLeadingView: () -> SecondLeadingView
    private let trailingView: () -> TrailingView

    public init(
        icon: ImageType,
        title: String,
        shouldShowTrailingIcon: Bool,
        action: @escaping () -> Void,
        @ViewBuilder secondLeadingView: @escaping () -> SecondLeadingView = EmptyView.init,
        @ViewBuilder trailingView: @escaping () -> TrailingView
    ) {
        self.icon = icon
        self.title = title
        self.action = action
        self.shouldShowTrailingIcon = shouldShowTrailingIcon
        self.secondLeadingView = secondLeadingView
        self.trailingView = trailingView
    }

    public var body: some View {
        Button(action: action) {
            BaseOneLineRow(
                icon: icon,
                title: title,
                secondLeadingView: secondLeadingView,
                trailingView: trailingView
            )
            .shouldShowTrailingIcon(shouldShowTrailingIcon)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
