//
//  AccountIconWithContentView.swift
//  TangemAccounts
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

public struct AccountIconWithContentView<Subtitle: View, Trailing: View>: View {
    let iconData: AccountIconView.ViewData
    let name: String
    let subtitle: Subtitle
    let trailing: Trailing

    private var iconSettings: AccountIconView.Settings = .defaultSized
    private var nameFontStyle = TangemFontStyle(font: Fonts.Bold.subheadline)
    private var nameColor: Color = Colors.Text.primary1
    private var subtitleFontStyle = TangemFontStyle(font: Fonts.Regular.caption1)
    private var subtitleColor: Color = Colors.Text.tertiary

    public init(
        iconData: AccountIconView.ViewData,
        name: String,
        @ViewBuilder subtitle: () -> Subtitle,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.iconData = iconData
        self.name = name
        self.subtitle = subtitle()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 0) {
            AccountIconView(data: iconData, settings: iconSettings)
                .padding(.trailing, 12)

            contentStack

            Spacer(minLength: 8)

            trailing
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1000.0)
        }
        .contentShape(Rectangle())
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text(name)
                .style(nameFontStyle, color: nameColor)
                .lineLimit(1)

            subtitle
                .style(subtitleFontStyle, color: subtitleColor)
                .lineLimit(1)
        }
    }
}

// MARK: - Setupable protocol conformance

extension AccountIconWithContentView: Setupable {
    public func iconSettings(_ settings: AccountIconView.Settings) -> Self {
        map { $0.iconSettings = settings }
    }

    public func nameStyle(font: Font, color: Color) -> Self {
        nameStyle(font: TangemFontStyle(font: font), color: color)
    }

    public func nameStyle(font: TangemFontStyle, color: Color) -> Self {
        map {
            $0.nameFontStyle = font
            $0.nameColor = color
        }
    }

    public func nameStyle(font: TangemTypographyToken, color: Color) -> Self {
        nameStyle(font: TangemFontStyle(font), color: color)
    }

    public func subtitleStyle(font: Font, color: Color) -> Self {
        subtitleStyle(font: TangemFontStyle(font: font), color: color)
    }

    public func subtitleStyle(font: TangemFontStyle, color: Color) -> Self {
        map {
            $0.subtitleFontStyle = font
            $0.subtitleColor = color
        }
    }
}

// MARK: - Default Empty Trailing

public extension AccountIconWithContentView where Trailing == EmptyView {
    init(
        iconData: AccountIconView.ViewData,
        name: String,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.init(
            iconData: iconData,
            name: name,
            subtitle: subtitle,
            trailing: { EmptyView() }
        )
    }
}

// MARK: - Empty Trailing and Subtitle

public extension AccountIconWithContentView where Subtitle == EmptyView, Trailing == EmptyView {
    init(
        iconData: AccountIconView.ViewData,
        name: String,
    ) {
        self.init(
            iconData: iconData,
            name: name,
            subtitle: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview("Default vs Custom Styles", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: 16) {
        AccountIconWithContentView(
            iconData: .composite(backgroundColor: .blue, nameMode: .letter("M")),
            name: "Main",
            subtitle: { Text("Default legacy style") }
        )

        AccountIconWithContentView(
            iconData: .composite(backgroundColor: .green, nameMode: .letter("R")),
            name: "Redesigned",
            subtitle: { Text("Tangem DS tokens") }
        )
        .nameStyle(font: Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
        .subtitleStyle(font: Font.Tangem.Caption13.regular, color: .Tangem.Text.Neutral.tertiary)
    }
    .padding()
}
#endif // DEBUG
