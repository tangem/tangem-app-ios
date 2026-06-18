//
//  TangemButtonV2.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// Capsule-shaped DS-Core button. Always pill-shaped. The Material tier rides as the
/// associated value of `.material(_:)` — `.styleType(.material(.glass))` requests Liquid
/// Glass (iOS 26+, falls back to blur below), `.styleType(.material(.blur))` forces the
/// DS-Core blur recipe.
public struct TangemButtonV2: View, Setupable {
    private var content: Content
    private var size: Size = .x10
    private var styleType: StyleType = .brand
    private var horizontalLayout: HorizontalLayout = .intrinsic
    private var isLoading: Bool = false
    private var accessibilityLabel: String?
    @ScaledMetric private var iconSide = Size.x10.iconSize

    private let action: () -> Void

    public init(
        label: AttributedString,
        iconStart: ImageType? = nil,
        iconEnd: ImageType? = nil,
        accessibilityLabel: String?,
        action: @escaping () -> Void
    ) {
        content = .label(label, iconStart: iconStart, iconEnd: iconEnd)
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public init(
        icon: ImageType,
        accessibilityLabel: String?,
        action: @escaping () -> Void
    ) {
        content = .iconOnly(icon)
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public init(model: Model) {
        content = model.content
        size = model.size
        styleType = model.styleType
        horizontalLayout = model.horizontalLayout
        accessibilityLabel = model.accessibilityLabel
        action = model.action
        _iconSide = ScaledMetric(wrappedValue: model.size.iconSize, relativeTo: .body)
    }

    public var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(
            Style(
                content: content,
                size: size,
                styleType: styleType,
                horizontalLayout: horizontalLayout,
                isLoading: isLoading
            )
        )
        .ifLet(accessibilityLabel) { view, label in
            view.accessibilityLabel(Text(label))
        }
        .allowsHitTesting(!isLoading)
    }

    @ViewBuilder
    private var label: some View {
        switch content {
        case .label(let attributedString, let iconStart, let iconEnd):
            HStack(spacing: 8) {
                if let iconStart {
                    iconView(iconStart)
                }

                Text(attributedString)
                    .lineLimit(1)

                if let iconEnd {
                    iconView(iconEnd)
                }
            }
        case .iconOnly(let icon):
            iconView(icon)
        }
    }

    private func iconView(_ icon: ImageType) -> some View {
        icon.image
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSide, height: iconSide)
    }
}

// MARK: - Setupable setters

public extension TangemButtonV2 {
    func content(_ content: Content) -> Self {
        map { $0.content = content }
    }

    func size(_ size: Size) -> Self {
        map {
            $0.size = size
            $0._iconSide = ScaledMetric(wrappedValue: size.iconSize, relativeTo: .body)
        }
    }

    func styleType(_ styleType: StyleType) -> Self {
        map { $0.styleType = styleType }
    }

    func horizontalLayout(_ horizontalLayout: HorizontalLayout) -> Self {
        map { $0.horizontalLayout = horizontalLayout }
    }

    func isLoading(_ isLoading: Bool) -> Self {
        map { $0.isLoading = isLoading }
    }

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibilityLabel = label }
    }
}
