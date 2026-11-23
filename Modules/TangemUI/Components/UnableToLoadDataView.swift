//
//  UnableToLoadDataView.swift
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

public struct UnableToLoadDataView: View {
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

            Button(
                label: Localization.tryToLoadDataAgainButtonTitle,
                accessibilityLabel: nil,
                action: retryButtonAction
            )
            .loading(.spinner(if: isButtonBusy))
            .styleType(.secondary(.default))
            .size(.x8)
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.retryButton)
        }
    }
}

// MARK: - Previews

#Preview {
    struct PreviewHolder: View {
        @State var isLoading = false

        var body: some View {
            UnableToLoadDataView(isButtonBusy: isLoading) {
                isLoading = true
                Task { @MainActor in
                    try? await ContinuousClock().sleep(for: .seconds(2))
                    isLoading = false
                }
            }
        }
    }

    return PreviewHolder()
}
