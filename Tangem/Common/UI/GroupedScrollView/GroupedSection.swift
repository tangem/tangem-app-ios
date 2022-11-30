//
//  GroupedSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct GroupedSection<Model: Identifiable, Content: View, Footer: View, Header: View>: View {
    private let models: [Model]
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer

    private var verticalPadding: CGFloat = 12
    private var horizontalPadding: CGFloat = 16
    private var separatorStyle: SeparatorStyle = .single

    init(
        _ models: [Model],
        @ViewBuilder content: @escaping (Model) -> Content,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.models = models
        self.content = content
        self.header = header
        self.footer = footer
    }

    init(
        _ model: Model?,
        @ViewBuilder content: @escaping (Model) -> Content,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.init(
            model == nil ? [] : [model!],
            content: content,
            header: header,
            footer: footer
        )
    }

    var body: some View {
        if !models.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                header()
                    .padding(.horizontal, horizontalPadding)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(models) { model in
                        content(model)
                            .padding(.horizontal, horizontalPadding)

                        if models.last?.id != model.id {
                            separator
                        }
                    }
                }
                .background(Colors.Background.primary)
                .cornerRadius(12)

                footer()
                    .padding(.horizontal, horizontalPadding)
            }
            .padding(.vertical, verticalPadding)
        }
    }

    @ViewBuilder private var separator: some View {
        switch separatorStyle {
        case .none:
            EmptyView()
        case .single:
            Colors.Stroke.primary
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .padding(.leading, separatorPadding)
        }
    }
}

extension GroupedSection: Setupable {
    func separatorPadding(_ padding: CGFloat) -> Self {
        map { $0.separatorPadding = padding }
    }
}

extension GroupedSection {
    enum SeparatorStyle: Int, Hashable {
        case none
        case single
    }
}

extension GroupedSection: Setupable {
    func verticalPadding(_ padding: CGFloat) -> Self {
        map { $0.verticalPadding = padding }
    }

    func horizontalPadding(_ padding: CGFloat) -> Self {
        map { $0.horizontalPadding = padding }
    }

    func separatorStyle(_ style: SeparatorStyle) -> Self {
        map { $0.separatorStyle = style }
    }
}
