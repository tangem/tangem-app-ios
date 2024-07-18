//
//  GroupedSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

/**
 Layout:
 `Background`
    `- innerContentPadding`
        `Header`
        `- interItemSpacing`
        `Content 1`
        `- interItemSpacing`
        `Content 2`
    `- innerContentPadding`
 `Background`
 `- footerSpacing`
 `Footer`
 */
struct GroupedSection<Model: Identifiable, Content: View, Footer: View, Header: View>: View {
    private let models: [Model]
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer

    private var settings: Settings = .init()

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
        models = model.map { [$0] } ?? []
        self.content = content
        self.header = header
        self.footer = footer
    }

    var body: some View {
        if !models.isEmpty {
            VStack(alignment: .leading, spacing: GroupedSectionConstants.footerSpacing) {
                VStack(alignment: settings.contentAlignment, spacing: settings.interItemSpacing) {
                    header()
                        .padding(.horizontal, settings.horizontalPadding)

                    ForEach(models) { model in
                        content(model)
                            .padding(.horizontal, settings.horizontalPadding)

                        if models.last?.id != model.id {
                            separator
                                .matchedGeometryEffect(settings.separatorGeometryEffect(model))
                        }
                    }
                }
                .padding(.vertical, settings.innerContentPadding)
                .background(
                    settings.backgroundColor
                        .matchedGeometryEffect(settings.backgroundGeometryEffect)
                )
                .cornerRadiusContinuous(GroupedSectionConstants.defaultCornerRadius)

                footer()
                    .padding(.horizontal, settings.horizontalPadding)
            }
        }
    }

    @ViewBuilder private var separator: some View {
        switch settings.separatorStyle {
        case .none:
            EmptyView()
        case .single:
            Colors.Stroke.primary
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .padding(.leading, settings.horizontalPadding)
        case .minimum:
            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.leading, settings.horizontalPadding)
        }
    }
}

extension GroupedSection {
    enum SeparatorStyle: Int, Hashable {
        case none
        case single
        case minimum
    }

    struct Settings {
        var horizontalPadding: CGFloat = GroupedSectionConstants.defaultHorizontalPadding
        var separatorStyle: SeparatorStyle = .minimum
        var interItemSpacing: CGFloat = 0
        var innerContentPadding: CGFloat = 0

        // Use "Colors.Background.primary" as default with "Colors.Background.secondary" background
        // Use "Colors.Background.action" on sheets with "Colors.Background.teritary" background
        var backgroundColor: Color = Colors.Background.primary
        var contentAlignment: HorizontalAlignment = .leading
        var innerHeaderPadding: CGFloat = GroupedSectionConstants.headerSpacing

        var backgroundGeometryEffect: GeometryEffect?
        var separatorGeometryEffect: (Model) -> GeometryEffect? = { _ in nil }
    }
}

enum GroupedSectionConstants {
    static let defaultHorizontalPadding: CGFloat = 14
    static let defaultCornerRadius: CGFloat = 14
    static let headerSpacing: CGFloat = 12
    static let footerSpacing: CGFloat = 8
}

// MARK: - Setupable

extension GroupedSection: Setupable {
    func settings(_ settings: Settings) -> Self {
        map { $0.settings = settings }
    }

    func settings<V>(_ keyPath: WritableKeyPath<Settings, V>, _ value: V) -> Self {
        map { $0.settings[keyPath: keyPath] = value }
    }

    func horizontalPadding(_ padding: CGFloat) -> Self {
        settings(\.horizontalPadding, padding)
    }

    func separatorStyle(_ style: SeparatorStyle) -> Self {
        settings(\.separatorStyle, style)
    }

    func interItemSpacing(_ spacing: CGFloat) -> Self {
        settings(\.interItemSpacing, spacing)
    }

    func innerContentPadding(_ padding: CGFloat) -> Self {
        settings(\.innerContentPadding, padding)
    }

    func innerHeaderPadding(_ padding: CGFloat) -> Self {
        settings(\.innerHeaderPadding, padding)
    }

    func backgroundColor(_ color: Color) -> Self {
        settings(\.backgroundColor, color)
    }

    func contentAlignment(_ alignment: HorizontalAlignment) -> Self {
        settings(\.contentAlignment, alignment)
    }

    func geometryEffect(_ geometryEffect: GeometryEffect?) -> Self {
        settings(\.backgroundGeometryEffect, geometryEffect)
    }
}
