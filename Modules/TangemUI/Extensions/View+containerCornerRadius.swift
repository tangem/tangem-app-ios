//
//  View+containerCornerRadius.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func containerCornerRadius(_ cornerRadius: CGFloat) -> some View {
        modifier(ContainerCornerRadiusModifier(cornerRadius: cornerRadius))
    }
}

public extension EnvironmentValues {
    @Entry var containerCornerRadius: CGFloat?
}

// MARK: - Modifier

private struct ContainerCornerRadiusModifier: ViewModifier {
    let cornerRadius: CGFloat

    @Environment(\.containerCornerRadius) private var inheritedCornerRadius

    func body(content: Content) -> some View {
        content.environment(\.containerCornerRadius, max(cornerRadius, inheritedCornerRadius ?? 0))
    }
}
