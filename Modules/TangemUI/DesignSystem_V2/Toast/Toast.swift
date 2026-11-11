//
//  Toast.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

public struct ToastView: View, Setupable {
    let label: String
    let appearance: ToastAppearance
    var action: ToastAction?
    var isClosable = true

    @Environment(\.toastDismissAction) private var dismissAction
    @Environment(\.toastTransition) private var transition
    @ScaledMetric private var iconSize = ToastMetrics.iconSize
    @ScaledMetric private var minHeight = ToastMetrics.minHeight

    public init(_ label: String, appearance: ToastAppearance = .neutral(icon: nil)) {
        self.label = label
        self.appearance = appearance
    }

    public var body: some View {
        HStack(spacing: ToastMetrics.spacing) {
            content

            if let action {
                actionButton(action)
            }

            if isClosable {
                closeButton
            }
        }
        .padding(ToastMetrics.padding)
        .frame(minHeight: minHeight)
        .opacity(transition.isContentVisible ? 1 : 0)
        .blur(radius: transition.isContentVisible ? 0 : ToastMetrics.hiddenContentBlur)
        .background { surface }
    }

    private var surface: some View {
        Color.clear
            .tangemMaterialSurface(
                in: RoundedRectangle(cornerRadius: ToastMetrics.cornerRadius, style: .continuous),
                isVisible: transition.isSurfaceVisible
            )
            .frame(width: transition.surfaceSize?.width, height: transition.surfaceSize?.height)
    }

    private var content: some View {
        HStack(spacing: 0) {
            if let icon = appearance.icon {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(appearance.iconColor)
                    .accessibilityHidden(true)
            }

            Text(label)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(ToastMetrics.labelLineLimit)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ToastMetrics.labelHorizontalPadding)
        }
        .padding(.horizontal, ToastMetrics.contentHorizontalPadding)
    }

    private func actionButton(_ action: ToastAction) -> some View {
        Button(label: action.title, accessibilityLabel: action.accessibilityLabel) {
            action.handler()
            dismissAction?.closure()
        }
        .styleType(.secondary(.default))
        .size(.x7)
    }

    private var closeButton: some View {
        Button(icon: DesignSystem.Icons.Cross.regular16, accessibilityLabel: Localization.commonClose) {
            dismissAction?.closure()
        }
        .styleType(.secondary(.default))
        .size(.x7)
    }
}

// MARK: - Setupable setters

public extension ToastView {
    func action(_ title: String, accessibilityLabel: String? = nil, action: @escaping () -> Void) -> Self {
        map { $0.action = ToastAction(title: title, accessibilityLabel: accessibilityLabel, handler: action) }
    }

    func closable(_ isClosable: Bool) -> Self {
        map { $0.isClosable = isClosable }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 8) {
        ToastView("Address copied", appearance: .neutral(icon: DesignSystem.Icons.Checkmark.regular20))
        ToastView("Something went wrong", appearance: .error)
            .closable(false)
        ToastView("Balance is currently hidden", appearance: .info)
            .action("Unhide") {}
        ToastView("Long toast message that wraps onto more lines and keeps going until it is cut after the third line, with an ellipsis at the end of it")
    }
    .padding(16)
}
