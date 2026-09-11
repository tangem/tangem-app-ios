//
//  PersonalDetailsKeyboardToolbar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PersonalDetailsKeyboardToolbar: View {
    let hasFieldBefore: Bool
    let hasFieldAfter: Bool
    let action: (Action) -> Void

    var body: some View {
        HStack {
            navigationGroup

            Spacer()

            dismissButton
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: Self.height)
    }
}

// MARK: - Metrics

extension PersonalDetailsKeyboardToolbar {
    static let height: CGFloat = Constants.controlHeight + Constants.groupPadding * 2
}

// MARK: - Controls

private extension PersonalDetailsKeyboardToolbar {
    var navigationGroup: some View {
        HStack(spacing: 4) {
            // [REDACTED_TODO_COMMENT]
            navigationButton(
                icon: DesignSystem.Icons.ChevronUp.regular20,
                isEnabled: hasFieldBefore,
                action: { action(.focusPrevious) }
            )

            // [REDACTED_TODO_COMMENT]
            navigationButton(
                icon: DesignSystem.Icons.ChevronDown.regular20,
                isEnabled: hasFieldAfter,
                action: { action(.focusNext) }
            )
        }
        .padding(Constants.groupPadding)
        .tangemMaterialSurface(in: Capsule(style: .circular))
    }

    func navigationButton(
        icon: ImageType,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        SwiftUI.Button(action: action) {
            icon.image
                .renderingMode(.template)
                .foregroundStyle(isEnabled ? DesignSystem.Color.iconPrimary : DesignSystem.Color.iconTertiary)
                .frame(width: Constants.controlHeight, height: Constants.controlHeight)
                .contentShape(.rect)
        }
        .disabled(!isEnabled)
    }

    var dismissButton: some View {
        // [REDACTED_TODO_COMMENT]
        TangemUI.Button(
            icon: DesignSystem.Icons.Checkmark.regular20,
            accessibilityLabel: nil,
            action: { action(.dismissKeyboard) }
        )
        .size(.x10)
        .styleType(.default)
    }
}

// MARK: - Constants

private extension PersonalDetailsKeyboardToolbar {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let groupPadding: CGFloat = 4
        static let controlHeight: CGFloat = 36
    }
}

// MARK: - Action

extension PersonalDetailsKeyboardToolbar {
    enum Action {
        case focusPrevious
        case focusNext
        case dismissKeyboard
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        PersonalDetailsKeyboardToolbar(
            hasFieldBefore: false,
            hasFieldAfter: true,
            action: { _ in }
        )

        PersonalDetailsKeyboardToolbar(
            hasFieldBefore: true,
            hasFieldAfter: true,
            action: { _ in }
        )

        PersonalDetailsKeyboardToolbar(
            hasFieldBefore: true,
            hasFieldAfter: false,
            action: { _ in }
        )
    }
    .frame(maxWidth: .infinity)
}
