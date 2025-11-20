//
//  BaseOneLineRow.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct BaseOneLineRow<SecondLeadingView: View, TitleView: View, TrailingView: View>: View {
    private let icon: ImageType?
    private let titleView: TitleView
    private let secondLeadingView: SecondLeadingView
    private let trailingView: TrailingView

    private var shouldShowTrailingIcon: Bool = true

    public var body: some View {
        HStack(alignment: .center, spacing: .zero) {
            leadingView

            Spacer()

            HStack(alignment: .center, spacing: 4) {
                trailingView

                if shouldShowTrailingIcon {
                    trailingIcon
                }
            }
        }
    }

    var leadingView: some View {
        HStack(alignment: .center, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                leadingIcon

                titleView
            }

            secondLeadingView
        }
    }

    var leadingIcon: some View {
        icon?.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.accent)
            .frame(width: 24, height: 24)
    }

    @ViewBuilder
    var trailingIcon: some View {
        Assets.Glyphs.selectIcon.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Colors.Icon.informative)
            .frame(width: 18, height: 24)
    }
}

// MARK: - Setupable

extension BaseOneLineRow: Setupable {
    public func shouldShowTrailingIcon(_ shouldShowTrailingIcon: Bool) -> Self {
        map { $0.shouldShowTrailingIcon = shouldShowTrailingIcon }
    }
}

public extension BaseOneLineRow {
    init(
        icon: ImageType?,
        title: String,
        @ViewBuilder secondLeadingView: () -> SecondLeadingView = EmptyView.init,
        @ViewBuilder trailingView: () -> TrailingView
    ) where TitleView == BaseOneLineRowDefaultTitleView {
        self.init(
            icon: icon,
            titleView: { BaseOneLineRowDefaultTitleView(title: title) },
            secondLeadingView: secondLeadingView,
            trailingView: trailingView
        )
    }

    init(
        icon: ImageType?,
        @ViewBuilder titleView: () -> TitleView,
        @ViewBuilder secondLeadingView: () -> SecondLeadingView,
        @ViewBuilder trailingView: () -> TrailingView
    ) {
        self.icon = icon
        self.titleView = titleView()
        self.secondLeadingView = secondLeadingView()
        self.trailingView = trailingView()
    }
}
