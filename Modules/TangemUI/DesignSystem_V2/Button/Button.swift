//
//  Button.swift
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
public struct Button: View, Setupable {
    private var content: Content
    private var size: Size = .x10
    private var styleType: StyleType = .brand
    private var horizontalLayout: HorizontalLayout = .intrinsic
    private var loading: Loading?
    private var accessibilityLabel: String?
    @ScaledMetric private var iconSide = Size.x10.iconSize
    @ScaledMetric private var wrapperPadding = Size.x10.wrapperPadding
    @ScaledMetric private var horizontalPadding = Size.x10.horizontalPadding

    private let action: () -> Void

    public init(
        label: AttributedString,
        accessibilityLabel: String?,
        action: @escaping () -> Void
    ) {
        content = .label(label, iconStart: nil, iconEnd: nil)
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public init(
        label: String,
        accessibilityLabel: String?,
        action: @escaping () -> Void
    ) {
        self.init(
            label: AttributedString(label),
            accessibilityLabel: accessibilityLabel,
            action: action
        )
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
        _wrapperPadding = ScaledMetric(wrappedValue: model.size.wrapperPadding, relativeTo: .body)
        _horizontalPadding = ScaledMetric(wrappedValue: model.size.horizontalPadding, relativeTo: .body)
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            label
        }
        .buttonStyle(
            Style(
                content: content,
                size: size,
                styleType: styleType,
                horizontalLayout: horizontalLayout
            )
        )
        .accessibilityLabel(Text(resolvedAccessibilityLabel))
        .allowsHitTesting(loading == nil)
    }

    private var isLoading: Bool {
        loading != nil
    }

    private var label: some View {
        ZStack {
            contentLabel
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                loadingRow
            }
        }
        .padding(.horizontal, iconOnlyLoadingMessagePadding)
        .accessibilityHidden(true)
    }

    /// Icon-only buttons carry no horizontal padding of their own, so a loading message needs it back
    /// to expand the circle into a pill.
    private var iconOnlyLoadingMessagePadding: CGFloat {
        guard case .iconOnly = content, loading?.message != nil else {
            return 0
        }

        return horizontalPadding
    }

    @ViewBuilder
    private var contentLabel: some View {
        switch content {
        case .label(let attributedString, let iconStart, let iconEnd):
            HStack(spacing: 0) {
                if let iconStart {
                    iconView(iconStart)
                }

                Text(attributedString)
                    .lineLimit(1)
                    .padding(.horizontal, wrapperPadding)

                if let iconEnd {
                    iconView(iconEnd)
                }
            }
        case .iconOnly(let icon):
            iconView(icon)
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 0) {
            Text(loading?.message ?? "")
                .lineLimit(1)
                .padding(.horizontal, loading?.message == nil ? 0 : wrapperPadding)

            loaderSlot
        }
    }

    private var loaderSlot: some View {
        Loader()
            .loaderSize(size.loaderSize)
            .loaderColor(styleType.foregroundColor)
            .frame(width: size.iconSize, height: size.iconSize)
    }

    private var resolvedAccessibilityLabel: String {
        if let message = loading?.message {
            return message
        }

        if let accessibilityLabel {
            return accessibilityLabel
        }

        guard case .label(let text, _, _) = content else {
            return ""
        }

        return String(text.characters)
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

public extension Button {
    func content(_ content: Content) -> Self {
        map { $0.content = content }
    }

    func iconStart(_ icon: ImageType?) -> Self {
        map {
            guard case .label(let text, _, let iconEnd) = $0.content else { return }
            $0.content = .label(text, iconStart: icon, iconEnd: iconEnd)
        }
    }

    func iconEnd(_ icon: ImageType?) -> Self {
        map {
            guard case .label(let text, let iconStart, _) = $0.content else { return }
            $0.content = .label(text, iconStart: iconStart, iconEnd: icon)
        }
    }

    func size(_ size: Size) -> Self {
        map {
            $0.size = size
            $0._iconSide = ScaledMetric(wrappedValue: size.iconSize, relativeTo: .body)
            $0._wrapperPadding = ScaledMetric(wrappedValue: size.wrapperPadding, relativeTo: .body)
            $0._horizontalPadding = ScaledMetric(wrappedValue: size.horizontalPadding, relativeTo: .body)
        }
    }

    func styleType(_ styleType: StyleType) -> Self {
        map { $0.styleType = styleType }
    }

    func horizontalLayout(_ horizontalLayout: HorizontalLayout) -> Self {
        map { $0.horizontalLayout = horizontalLayout }
    }

    func loading(_ loading: Loading?) -> Self {
        map { $0.loading = loading }
    }

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibilityLabel = label }
    }
}

extension Button {
    func iconSize(_ side: CGFloat) -> Self {
        map { $0._iconSide = ScaledMetric(wrappedValue: side, relativeTo: .body) }
    }
}
