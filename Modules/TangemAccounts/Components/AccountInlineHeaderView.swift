//
//  AccountInlineHeaderView.swift
//  TangemAccounts
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct AccountInlineHeaderView: View {
    private let iconData: AccountIconView.ViewData
    private let name: String

    private var iconSettings: AccountIconView.Settings = .extraSmallSized
    private var spacing: CGFloat = Constants.spacing
    private var font: Font = Fonts.Bold.footnote
    private var textColor: Color = Colors.Text.primary1
    private var expandsHorizontally: Bool = false
    private var iconGeometryEffect: GeometryEffectPropertiesModel?
    private var iconBackgroundGeometryEffect: GeometryEffectPropertiesModel?
    private var nameGeometryEffect: GeometryEffectPropertiesModel?
    private var minimumScaleFactor: CGFloat = 0.7

    public init(
        iconData: AccountIconView.ViewData,
        name: String
    ) {
        self.iconData = iconData
        self.name = name
    }

    public var body: some View {
        HStack(spacing: spacing) {
            AccountIconView(
                data: iconData,
                settings: iconSettings,
                iconGeometryEffect: iconGeometryEffect,
                backgroundGeometryEffect: iconBackgroundGeometryEffect
            )

            Text(name)
                .style(font, color: textColor)
                .matchedGeometryEffect(nameGeometryEffect)
                .minimumScaleFactor(minimumScaleFactor)
                .lineLimit(1)

            if expandsHorizontally {
                Spacer()
            }
        }
    }
}

// MARK: - Constants

public extension AccountInlineHeaderView {
    enum Constants {
        public static let spacing: CGFloat = 6
    }
}

// MARK: - Setupable

extension AccountInlineHeaderView: Setupable {
    public func iconSettings(_ settings: AccountIconView.Settings) -> Self {
        map { $0.iconSettings = settings }
    }

    public func font(_ font: Font) -> Self {
        map { $0.font = font }
    }

    public func textColor(_ color: Color) -> Self {
        map { $0.textColor = color }
    }

    public func nameStyle(_ font: Font, color: Color) -> Self {
        map {
            $0.font = font
            $0.textColor = color
        }
    }

    public func expandsHorizontally(_ expands: Bool) -> Self {
        map { $0.expandsHorizontally = expands }
    }

    public func iconGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        map { $0.iconGeometryEffect = effect }
    }

    public func iconBackgroundGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        map { $0.iconBackgroundGeometryEffect = effect }
    }

    public func nameGeometryEffect(_ effect: GeometryEffectPropertiesModel?) -> Self {
        map { $0.nameGeometryEffect = effect }
    }

    public func minimumScaleFactor(_ minimumScaleFactor: CGFloat) -> Self {
        map { $0.minimumScaleFactor = minimumScaleFactor }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 16) {
        AccountInlineHeaderView(
            iconData: .init(backgroundColor: .blue, nameMode: .letter("A")),
            name: "Account 1"
        )

        AccountInlineHeaderView(
            iconData: .init(backgroundColor: .green, nameMode: .letter("B")),
            name: "Account 2"
        )
        .iconSettings(.smallSized)
        .font(Fonts.Bold.subheadline)

        AccountInlineHeaderView(
            iconData: .init(backgroundColor: .orange, nameMode: .letter("C")),
            name: "Account 3"
        )
        .expandsHorizontally(true)
    }
    .padding()
}
#endif
