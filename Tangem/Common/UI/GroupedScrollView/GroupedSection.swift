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

    private var horizontalPadding: CGFloat = 14
    private var separatorStyle: SeparatorStyle = .minimum
    private var interItemSpacing: CGFloat = 0
    private var innerContentPadding: CGFloat = 0
    private var backgroundColor: Color = Colors.Background.action
    private var contentAlignment: HorizontalAlignment = .leading

    private var namespace: Namespace.ID?
    private var backgroundNamespaceId: String?

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

                VStack(alignment: contentAlignment, spacing: interItemSpacing) {
                    ForEach(models) { model in
                        content(model)
                            .padding(.horizontal, horizontalPadding)

                        if models.last?.id != model.id {
                            separator
                        }
                    }
                }
                .padding(.vertical, innerContentPadding)
                .background(backgroundColor)
                .cornerRadiusContinuous(14)

                footer()
                    .padding(.horizontal, horizontalPadding)
            }
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
                .padding(.leading, horizontalPadding)
        case .minimum:
            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.leading, horizontalPadding)
        }
    }
}

/*
 body: some View {
        if !models.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                header()
                    .padding(.horizontal, horizontalPadding)

                ZStack {
                    Rectangle()
                        .fill(Color.red)
                        .matchedGeometryEffect(id: backgroundNamespaceId, in: namespace)
                        .overlay(
                            Text("\(backgroundNamespaceId ?? "nil") \(namespace?.hashValue ?? -1)")
                                .foregroundColor(.white)
                        )

                    VStack(alignment: contentAlignment, spacing: interItemSpacing) {
                        ForEach(models) { model in
                            content(model)
                                .padding(.horizontal, horizontalPadding)

                            if models.last?.id != model.id {
                                separator
                            }
                        }
                    }
                    .padding(.vertical, interSectionPadding)
                    //                .background(
                    //                    backgroundColor
                    //                        .matchedGeometryEffect(id: backgroundNamespaceId, in: namespace)
                    //                )
                    //                .overlay(
                    //                    Text("\(backgroundNamespaceId ?? "nil") \(namespace?.hashValue ?? -1)")
                    //                )
                }
                .cornerRadius(12)

                footer()
                    .padding(.horizontal, horizontalPadding)
            }
            .padding(.vertical, verticalPadding)
        }
 */

extension GroupedSection {
    enum SeparatorStyle: Int, Hashable {
        case none
        case single
        case minimum
    }
}

extension GroupedSection: Setupable {
    func horizontalPadding(_ padding: CGFloat) -> Self {
        map { $0.horizontalPadding = padding }
    }

    func separatorStyle(_ style: SeparatorStyle) -> Self {
        map { $0.separatorStyle = style }
    }

    func interItemSpacing(_ spacing: CGFloat) -> Self {
        map { $0.interItemSpacing = spacing }
    }

    func innerContentPadding(_ spacing: CGFloat) -> Self {
        map { $0.innerContentPadding = spacing }
    }

    func backgroundColor(_ color: Color, id backgroundNamespaceId: String? = nil, namespace: Namespace.ID? = nil) -> Self {
        map {
            $0.backgroundColor = color
            $0.namespace = namespace
            $0.backgroundNamespaceId = backgroundNamespaceId
        }
    }

    func contentAlignment(_ alignment: HorizontalAlignment) -> Self {
        map { $0.contentAlignment = alignment }
    }
}
