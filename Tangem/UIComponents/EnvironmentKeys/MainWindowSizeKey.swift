//
//  MainWindowSizeKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

private struct MainWindowSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var mainWindowSize: CGSize {
        get { self[MainWindowSizeKey.self] }
        set { self[MainWindowSizeKey.self] = newValue }
    }
}

extension View {
    func mainWindowSize(initial initialSize: CGSize) -> some View {
        modifier(MainWindowSizeModifier(initialSize: initialSize))
    }
}

private struct MainWindowSizeModifier: ViewModifier {
    let initialSize: CGSize

    @State private var measuredSize: CGSize?

    func body(content: Content) -> some View {
        content
            .environment(\.mainWindowSize, measuredSize ?? initialSize)
            .background {
                Color.clear
                    .ignoresSafeArea()
                    .onGeometryChange(for: CGSize.self, of: \.size) { measuredSize = $0 }
            }
    }
}
