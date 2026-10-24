//
//  DSShowcaseEnvironment.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets

struct DSShowcaseEnvironment: Equatable {
    var isRTL = false
    var appearance: Appearance = .system
    var dynamicTypeSize: DynamicTypeSize?
    var reduceMotion: Bool?
    var background: DSShowcaseStageBackground = .primary

    var summary: String {
        [
            isRTL ? "RTL" : "LTR",
            String(describing: appearance),
            dynamicTypeSize.map { String(describing: $0) } ?? "system DT",
            reduceMotion.map { $0 ? "reduce motion" : "full motion" },
            String(describing: background),
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }
}

extension DSShowcaseEnvironment {
    enum Appearance: CaseIterable {
        case system
        case light
        case dark
    }
}

enum DSShowcaseStageBackground: CaseIterable {
    case primary
    case secondary
    case tertiary
    case inverse
    case gradient

    @ViewBuilder
    var view: some View {
        switch self {
        case .primary:
            DesignSystem.Color.bgPrimary
        case .secondary:
            DesignSystem.Color.bgSecondary
        case .tertiary:
            DesignSystem.Color.bgTertiary
        case .inverse:
            DesignSystem.Color.bgInverse
        case .gradient:
            LinearGradient(
                colors: [
                    DesignSystem.Color.bgAccentBlue,
                    DesignSystem.Color.bgAccentViolet,
                    DesignSystem.Color.bgAccentOrange,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension View {
    func showcaseEnvironment(_ environment: DSShowcaseEnvironment) -> some View {
        modifier(DSShowcaseEnvironmentModifier(environment: environment))
    }
}

private struct DSShowcaseEnvironmentModifier: ViewModifier {
    let environment: DSShowcaseEnvironment

    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, environment.isRTL ? .rightToLeft : .leftToRight)
            .environment(\.colorScheme, colorScheme)
            .environment(\.dynamicTypeSize, environment.dynamicTypeSize ?? systemDynamicTypeSize)
            .environment(\._accessibilityReduceMotion, environment.reduceMotion ?? systemReduceMotion)
    }

    private var colorScheme: ColorScheme {
        switch environment.appearance {
        case .system: systemColorScheme
        case .light: .light
        case .dark: .dark
        }
    }
}
#endif
