//
//  TokenDetailsActionsButtonsRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokenDetailsActionsButtonsRowView: View {
    let buttons: [TokenDetailsActionsButton]

    @ScaledMetric(wrappedValue: .unit(.x6)) private var spacing: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(buttons) { button in
                TangemMainActionButton(
                    title: button.title,
                    icon: button.icon,
                    action: button.action,
                    reasonTapWhenDisabled: button.action
                )
                .disabled(!button.isAvailable)
                .ifLet(button.longPressAction) { view, longPressAction in
                    view.simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in longPressAction() }
                    )
                }
                .accessibilityIdentifier(button.accessibilityIdentifier)
            }
        }
    }
}

struct TokenDetailsActionsButton: Identifiable {
    let id: TokenDetailsActionsKind
    let title: String
    let icon: ImageType
    let accessibilityIdentifier: String?
    let isAvailable: Bool
    let action: () -> Void
    let longPressAction: (() -> Void)?
}

enum TokenDetailsActionsKind: String {
    case addFunds
    case swap
    case transfer
}
