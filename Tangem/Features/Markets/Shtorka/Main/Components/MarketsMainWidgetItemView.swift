//
//  MarketsMainWidgetItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsMainWidgetItemView<Header: View, Content: View, Footer: View>: View {
    private let header: (() -> Header)?
    private let content: () -> Content
    private let footer: () -> Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let header {
                header()
            }

            content()

            footer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    init(
        header: (() -> Header)? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.header = header
        self.content = content
        self.footer = footer
    }

    // MARK: - Backward compatible convenience initializers

    init(
        title: String?,
        content: Content
    ) where Header == MarketsMainWidgetItemHeaderView, Footer == EmptyView {
        header = { MarketsMainWidgetItemHeaderView(title: title) }
        self.content = { content }
        footer = { EmptyView() }
    }

    init(
        title: String?,
        @ViewBuilder content: @escaping () -> Content
    ) where Header == MarketsMainWidgetItemHeaderView, Footer == EmptyView {
        header = { MarketsMainWidgetItemHeaderView(title: title) }
        self.content = content
        footer = { EmptyView() }
    }
}
