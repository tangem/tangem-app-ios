//
//  CollectiblesDevnetMenu.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// [REDACTED_TODO_COMMENT]
// four go away once testers can top up on a network of their own.
struct CollectiblesDevnetMenu: View {
    let viewModel: CollectiblesDevnetMenuViewModel?

    var body: some View {
        if let viewModel {
            Divider()

            SwiftUI.Button(action: viewModel.onCopyTopUpAddressTap) {
                Label(
                    title: { Text("Copy USDC address") },
                    icon: { DesignSystem.Icons.Copy.regular20.image.renderingMode(.template) }
                )
            }

            SwiftUI.Button(action: viewModel.onCopyFeePayerAddressTap) {
                Label(
                    title: { Text("Copy SOL address") },
                    icon: { DesignSystem.Icons.Copy.regular20.image.renderingMode(.template) }
                )
            }

            SwiftUI.Button(action: viewModel.onCopyPurchaseFeePayerAddressTap) {
                Label(
                    title: { Text("Copy purchase SOL address") },
                    icon: { DesignSystem.Icons.Copy.regular20.image.renderingMode(.template) }
                )
            }

            SwiftUI.Button(role: .destructive, action: viewModel.onCloseAccountTap) {
                Label(
                    title: { Text("Close account") },
                    icon: { DesignSystem.Icons.TrashBin.regular20.image.renderingMode(.template) }
                )
            }
        }
    }
}

// MARK: - Alert

/// The menu closes on selection, so the confirmation has to be raised by something that stays on screen.
private struct CollectiblesDevnetAlertModifier: ViewModifier {
    @ObservedObject var viewModel: CollectiblesDevnetMenuViewModel

    func body(content: Content) -> some View {
        content.alert(item: $viewModel.alert) { $0.alert }
    }
}

extension View {
    // [REDACTED_TODO_COMMENT]
    @ViewBuilder
    func collectiblesDevnetAlert(_ viewModel: CollectiblesDevnetMenuViewModel?) -> some View {
        if let viewModel {
            modifier(CollectiblesDevnetAlertModifier(viewModel: viewModel))
        } else {
            self
        }
    }

    // [REDACTED_TODO_COMMENT]
    @ViewBuilder
    func collectiblesDevnetProgress(_ viewModel: CollectiblesDevnetMenuViewModel?) -> some View {
        if let viewModel {
            modifier(CollectiblesDevnetProgressModifier(viewModel: viewModel))
        } else {
            self
        }
    }
}

// MARK: - Progress

/// Closing is a chain operation that takes tens of seconds, so the content is covered rather than annotated
/// with a toast. The navigation bar stays reachable on purpose: leaving does not cancel the close, the task
/// holds the actions itself and carries it through.
private struct CollectiblesDevnetProgressModifier: ViewModifier {
    @ObservedObject var viewModel: CollectiblesDevnetMenuViewModel

    func body(content: Content) -> some View {
        content.overlay {
            if viewModel.isClosing {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)

                    Text("Closing the account…")
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Text("Closing continues even if you leave the screen")
                        .multilineTextAlignment(.center)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .padding(24)
                .infinityFrame()
                .background(DesignSystem.Color.bgPrimary.opacity(0.95).ignoresSafeArea())
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.isClosing)
    }
}
