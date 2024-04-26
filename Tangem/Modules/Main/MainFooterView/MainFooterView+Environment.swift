//
//  MainFooterView+Environment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

extension View {
    func isMainFooterVisible(
        _ isVisible: Bool
    ) -> some View {
        return environment(\.isMainFooterVisible, isVisible)
    }
}

extension EnvironmentValues {
    var isMainFooterVisible: Bool {
        get { self[MainFooterVisibilityEnvironmentKey.self] }
        set { self[MainFooterVisibilityEnvironmentKey.self] = newValue }
    }
}

// MARK: - Private implementation

private enum MainFooterVisibilityEnvironmentKey: EnvironmentKey {
    static var defaultValue: Bool { true }
}
