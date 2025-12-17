//
//  AppColorSchemeObserver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

enum AppColorSchemeObserver {
    static private(set) var appColorScheme: AppColorScheme = .unspecified

    static func update(colorScheme: ColorScheme) {
        switch colorScheme {
        case .light: appColorScheme = .light
        case .dark: appColorScheme = .dark
        @unknown default: appColorScheme = .unspecified
        }
    }

    public enum AppColorScheme {
        case light
        case dark
        case unspecified
    }
}

// MARK: - View+

extension View {
    func observeAppColorScheme() -> some View {
        modifier(AppColorSchemeObserverViewModifier())
    }
}

// MARK: - ViewModifier

private struct AppColorSchemeObserverViewModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .onAppear { AppColorSchemeObserver.update(colorScheme: colorScheme) }
            .onChange(of: colorScheme) { AppColorSchemeObserver.update(colorScheme: $0) }
    }
}
