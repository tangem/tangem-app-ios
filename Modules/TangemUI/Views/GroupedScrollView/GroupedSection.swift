//
//  GroupedSection.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

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
public struct GroupedSection<Model: Identifiable, Content: View, Footer: View, Header: View, EmptyContent: View>: View {
    private let models: [Model]
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer
    private let emptyContent: () -> EmptyContent

    private var settings: Settings = .init()

    private var isEmptyContentRequired: Bool {
        EmptyContent.self != EmptyView.self
    }

    public init(
        _ models: [Model],
        @ViewBuilder content: @escaping (Model) -> Content,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) {
        self.models = models
        self.content = content
        self.header = header
        self.footer = footer
        self.emptyContent = emptyContent
    }

    public init(
        _ model: Model?,
        @ViewBuilder content: @escaping (Model) -> Content,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
        @ViewBuilder emptyContent: @escaping () -> EmptyContent = { EmptyView() }
    ) {
        models = model.map { [$0] } ?? []
        self.content = content
        self.header = header
        self.footer = footer
        self.emptyContent = emptyContent
    }

    public var body: some View {
        if models.isNotEmpty || isEmptyContentRequired {
            groupedContent
        }
    }

    private var groupedContent: some View {
        VStack(alignment: .leading, spacing: GroupedSectionConstants.footerSpacing) {
            VStack(alignment: settings.contentAlignment, spacing: settings.interItemSpacing) {
                header()
                    .padding(.horizontal, settings.horizontalPadding)

                modelsList
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

    @ViewBuilder
    private var modelsList: some View {
        if models.isNotEmpty {
            ForEach(models) { model in
                content(model)
                    .padding(.horizontal, settings.horizontalPadding)

                if models.last?.id != model.id {
                    separator
                        .matchedGeometryEffect(settings.separatorGeometryEffect(model))
                }
            }
        } else {
            emptyContent()
                .padding(.horizontal, settings.horizontalPadding)
        }
    }

    @ViewBuilder
    private var separator: some View {
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
                .padding(.horizontal, settings.horizontalPadding)
        }
    }
}

public extension GroupedSection {
    enum SeparatorStyle: Int, Hashable {
        case none
        case single
        case minimum
    }

    struct Settings {
        public var horizontalPadding: CGFloat = GroupedSectionConstants.defaultHorizontalPadding
        public var separatorStyle: SeparatorStyle = .minimum
        public var interItemSpacing: CGFloat = 0
        public var innerContentPadding: CGFloat = 0

        // Use "Colors.Background.primary" as default with "Colors.Background.secondary" background
        // Use "Colors.Background.action" on sheets with "Colors.Background.tertiary" background
        public var backgroundColor: Color = Colors.Background.primary
        public var contentAlignment: HorizontalAlignment = .leading
        public var innerHeaderPadding: CGFloat = GroupedSectionConstants.headerSpacing

        public var backgroundGeometryEffect: GeometryEffectPropertiesModel?
        public var separatorGeometryEffect: (Model) -> GeometryEffectPropertiesModel? = { _ in nil }
    }
}

public enum GroupedSectionConstants {
    public static let defaultHorizontalPadding: CGFloat = 14
    public static let defaultCornerRadius: CGFloat = 14
    public static let headerSpacing: CGFloat = 12
    public static let footerSpacing: CGFloat = 8
}

// MARK: - Setupable

extension GroupedSection: Setupable {
    public func settings(_ settings: Settings) -> Self {
        map { $0.settings = settings }
    }

    public func settings<V>(_ keyPath: WritableKeyPath<Settings, V>, _ value: V) -> Self {
        map { $0.settings[keyPath: keyPath] = value }
    }

    public func horizontalPadding(_ padding: CGFloat) -> Self {
        settings(\.horizontalPadding, padding)
    }

    public func separatorStyle(_ style: SeparatorStyle) -> Self {
        settings(\.separatorStyle, style)
    }

    public func interItemSpacing(_ spacing: CGFloat) -> Self {
        settings(\.interItemSpacing, spacing)
    }

    public func innerContentPadding(_ padding: CGFloat) -> Self {
        settings(\.innerContentPadding, padding)
    }

    public func innerHeaderPadding(_ padding: CGFloat) -> Self {
        settings(\.innerHeaderPadding, padding)
    }

    public func backgroundColor(_ color: Color) -> Self {
        settings(\.backgroundColor, color)
    }

    public func contentAlignment(_ alignment: HorizontalAlignment) -> Self {
        settings(\.contentAlignment, alignment)
    }

    public func geometryEffect(_ geometryEffect: GeometryEffectPropertiesModel?) -> Self {
        settings(\.backgroundGeometryEffect, geometryEffect)
    }
}
