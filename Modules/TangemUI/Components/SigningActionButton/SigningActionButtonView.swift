//
//  SigningActionButtonView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct SigningActionButtonView: View {
    private let type: SigningActionButtonViewType
    private let title: String
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    public init(
        type: SigningActionButtonViewType,
        title: String,
        isLoading: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        switch type {
        case .cardTap:
            Button(label: title, accessibilityLabel: nil, action: action)
                .iconEnd(DesignSystem.Icons.LogoTangem.regular24)
                .styleType(.primary)
                .size(.x12)
                .horizontalLayout(.infinity)
                .loading(.spinner(if: isLoading))
                .disabled(isDisabled)
        case .holdToConfirm:
            HoldToConfirmButton(
                title: title,
                isLoading: isLoading,
                isDisabled: isDisabled,
                action: action
            )
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        SigningActionButtonView(type: .cardTap, title: "Sign", isLoading: false, isDisabled: false, action: {})
        SigningActionButtonView(type: .cardTap, title: "Sign", isLoading: true, isDisabled: false, action: {})
        SigningActionButtonView(type: .cardTap, title: "Sign", isLoading: false, isDisabled: true, action: {})
        SigningActionButtonView(type: .holdToConfirm, title: "Sign", isLoading: false, isDisabled: false, action: {})
        SigningActionButtonView(type: .holdToConfirm, title: "Sign", isLoading: true, isDisabled: false, action: {})
        SigningActionButtonView(type: .holdToConfirm, title: "Sign", isLoading: false, isDisabled: true, action: {})
    }
    .padding(16)
    .background(DesignSystem.Color.bgSecondary)
}
