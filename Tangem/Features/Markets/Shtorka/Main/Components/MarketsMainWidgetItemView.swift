//
//  MarketsMainWidgetItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsMainWidgetItemView<Header: View, Content: View, Footer: View>: View {
    private typealias Constants = MarketsMainWidgetItemViewConstants

    private let header: () -> Header
    private let content: () -> Content
    private let footer: () -> Footer

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.interItemSpacing) {
            header()
                .padding(.horizontal, Constants.horizontalPadding)

            content()

            footer()
                .padding(.horizontal, Constants.horizontalPadding)
        }
        .padding(.vertical, Constants.innerContentPadding)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(Constants.cornerRadius)
    }

    init(
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.header = header
        self.content = content
        self.footer = footer
    }

    // MARK: - Backward compatible convenience initializers

    init(
        headerTitle: String,
        buttonTitle: String?,
        buttonAction: (() -> Void)?,
        content: Content
    ) where Header == MarketsCommonWidgetHeaderView, Footer == EmptyView {
        header = { MarketsCommonWidgetHeaderView(
            headerTitle: headerTitle,
            buttonTitle: buttonTitle,
            buttonAction: buttonAction
        ) }
        self.content = { content }
        footer = { EmptyView() }
    }

    init(
        headerTitle: String,
        buttonTitle: String?,
        buttonAction: (() -> Void)?,
        @ViewBuilder content: @escaping () -> Content
    ) where Header == MarketsCommonWidgetHeaderView, Footer == EmptyView {
        header = { MarketsCommonWidgetHeaderView(
            headerTitle: headerTitle,
            buttonTitle: buttonTitle,
            buttonAction: buttonAction
        ) }
        self.content = content
        footer = { EmptyView() }
    }
}

// MARK: - Constants

private enum MarketsMainWidgetItemViewConstants {
    static let horizontalPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 14
    static let interItemSpacing: CGFloat = 14
    static let innerContentPadding: CGFloat = 0
}
