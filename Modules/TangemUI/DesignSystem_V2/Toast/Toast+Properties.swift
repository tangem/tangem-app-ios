//
//  Toast+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public enum ToastAppearance {
    case neutral(icon: ImageType?)
    case error
    case info
    case success

    var icon: ImageType? {
        switch self {
        case .neutral(let icon): icon
        case .error: DesignSystem.Icons.Error.regular20
        case .info: DesignSystem.Icons.Info.regular20
        case .success: DesignSystem.Icons.Success.regular20
        }
    }

    var iconColor: Color {
        switch self {
        case .neutral: DesignSystem.Color.iconPrimary
        case .error: DesignSystem.Color.iconStatusError
        case .info: DesignSystem.Color.iconStatusInfo
        case .success: DesignSystem.Color.iconStatusSuccess
        }
    }
}

struct ToastAction {
    let title: String
    let accessibilityLabel: String?
    let handler: () -> Void
}

enum ToastMetrics {
    static let iconSize: CGFloat = 20
    static let minHeight: CGFloat = 44
    static let cornerRadius: CGFloat = 24
    static let padding: CGFloat = 8
    static let spacing: CGFloat = 4
    static let contentHorizontalPadding: CGFloat = 4
    static let labelHorizontalPadding: CGFloat = 8
    static let labelLineLimit = 3
    static let hiddenContentBlur: CGFloat = 32
}

struct ToastTransition: Equatable {
    var isContentVisible: Bool
    var isSurfaceVisible: Bool
    var surfaceSize: CGSize?

    static let shown = ToastTransition(isContentVisible: true, isSurfaceVisible: true, surfaceSize: nil)
}

struct ToastDismissAction: Equatable {
    private let id = UUID()

    let closure: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension EnvironmentValues {
    @Entry var toastDismissAction: ToastDismissAction? = nil
    @Entry var toastTransition: ToastTransition = .shown
}
