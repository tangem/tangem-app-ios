//
//  TangemUnableToLoadDataView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
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
        VStack(spacing: SizeUnit.x3.value) {
            Text(Localization.marketsLoadingErrorTitle)
                .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)

            TangemButton(
                content: .text(AttributedString(Localization.tryToLoadDataAgainButtonTitle)),
                action: retryButtonAction
            )
            .setButtonState(isLoading: isButtonBusy)
            .setStyleType(.secondary)
            .setCornerStyle(.rounded)
            .setHorizontalLayout(.intrinsic)
            .setSize(.x9)
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.retryButton)
        }
    }
}

// MARK: - Previews

#if DEBUG
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
#endif // DEBUG
