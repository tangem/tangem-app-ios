//
//  TangemLoader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// A rotating spinner that indicates loading activity.
///
/// Use ``loaderSize(_:)`` to choose one of the six discrete icon sizes (12 / 16 / 20 / 24 / 28 / 32 pt)
/// and ``loaderColor(_:)`` to tint the spinner for its placement context.
/// The default size is 24 pt and the default color is `DesignSystem.Tokens.Theme.Icon.primary`.
///
/// ```swift
/// TangemLoader()
///     .loaderSize(.size16)
///     .loaderColor(DesignSystem.Tokens.Theme.Icon.inverse)
/// ```
///
/// - Note: Dynamic Type scaling is not yet implemented — pending product testing (backlog).
public struct TangemLoader: View {
    private var size: Size = .size24
    private var color: Color = DesignSystem.Tokens.Theme.Icon.primary

    @State private var isRotating = false

    public init() {}

    public var body: some View {
        size.icon.image
            .renderingMode(.template)
            .foregroundStyle(color)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .task {
                isRotating = false
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    isRotating = true
                }
            }
            .onDisappear {
                isRotating = false
            }
    }
}

// MARK: - Setupable

extension TangemLoader: Setupable {
    public func loaderSize(_ size: Size) -> Self {
        map { $0.size = size }
    }

    public func loaderColor(_ color: Color) -> Self {
        map { $0.color = color }
    }
}

// MARK: - Size

public extension TangemLoader {
    enum Size: Sendable, Hashable, CaseIterable {
        case size12
        case size16
        case size20
        case size24
        case size28
        case size32

        var icon: ImageType {
            switch self {
            case .size12: DesignSystem.Icons.LoadingSpinner.regular12
            case .size16: DesignSystem.Icons.LoadingSpinner.regular16
            case .size20: DesignSystem.Icons.LoadingSpinner.regular20
            case .size24: DesignSystem.Icons.LoadingSpinner.regular24
            case .size28: DesignSystem.Icons.LoadingSpinner.regular28
            case .size32: DesignSystem.Icons.LoadingSpinner.regular32
            }
        }
    }
}
