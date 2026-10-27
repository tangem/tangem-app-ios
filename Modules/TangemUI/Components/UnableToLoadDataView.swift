//
//  UnableToLoadDataView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

// [REDACTED_TODO_COMMENT]
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
                .style(Fonts.Bold.caption1.weight(.medium), color: DesignSystem.Color.textSecondary)

            SwiftUI.Button(action: retryButtonAction, label: {
                HStack(spacing: .zero) {
                    Text(Localization.tryToLoadDataAgainButtonTitle)
                        .style(Fonts.Bold.caption1.weight(.medium), color: DesignSystem.Color.textPrimary)
                }
                .hidden(isButtonBusy)
                .overlay {
                    if isButtonBusy {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Color.iconSecondary))
                    }
                }
            })
            .roundedBackground(with: DesignSystem.Color.bgTransparentSecondary, verticalPadding: 6, horizontalPadding: 12, radius: 10)
            .disabled(isButtonBusy)
            .accessibilityIdentifier(CommonUIAccessibilityIdentifiers.retryButton)
        }
    }
}

#Preview {
    struct PreviewHolder: View {
        @State var isLoading = false

        var body: some View {
            UnableToLoadDataView(isButtonBusy: isLoading) {
                isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
        }
    }

    return PreviewHolder()
}
