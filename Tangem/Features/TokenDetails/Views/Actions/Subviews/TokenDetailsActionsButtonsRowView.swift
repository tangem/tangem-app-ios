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
                    buttonState: .normal,
                    action: button.action
                )
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
    let action: () -> Void
    let longPressAction: (() -> Void)?

    init(
        id: TokenDetailsActionsKind,
        title: String,
        icon: ImageType,
        accessibilityIdentifier: String?,
        action: @escaping () -> Void,
        longPressAction: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
        self.longPressAction = longPressAction
    }
}

enum TokenDetailsActionsKind: String {
    case addFunds
    case swap
    case transfer
}
