//
//  TangemUnableToLoadDataView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemLocalization
import TangemAccessibilityIdentifiers

public struct TangemUnableToLoadDataView: View {
    private let isButtonBusy: Bool
    private let retryButtonAction: () -> Void

    public init(isButtonBusy: Bool, retryButtonAction: @escaping () -> Void) {
        self.isButtonBusy = isButtonBusy
        self.retryButtonAction = retryButtonAction
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text(Localization.marketsLoadingErrorTitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            TangemButton(
                content: .text(AttributedString(Localization.tryToLoadDataAgainButtonTitle)),
                action: retryButtonAction
            )
            .setButtonState(isLoading: isButtonBusy)
            .setStyleType(.secondary)
            .setHorizontalLayout(.intrinsic)
            .setSize(.x9)
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.retryButton)
        }
    }
}

// MARK: - Previews

#Preview {
    struct PreviewHolder: View {
        @State var isLoading = false

        var body: some View {
            TangemUnableToLoadDataView(isButtonBusy: isLoading) {
                isLoading = true
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    isLoading = false
                }
            }
        }
    }

    return PreviewHolder()
}
