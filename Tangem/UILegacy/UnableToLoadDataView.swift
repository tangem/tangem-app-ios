//
//  UnableToLoadDataView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct UnableToLoadDataView: View {
    let isButtonBusy: Bool
    let retryButtonAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(Localization.marketsLoadingErrorTitle)
                .style(Fonts.Bold.caption1.weight(.medium), color: Colors.Text.tertiary)

            Button(action: retryButtonAction, label: {
                HStack(spacing: .zero) {
                    Text(Localization.tryToLoadDataAgainButtonTitle)
                        .style(Fonts.Bold.caption1.weight(.medium), color: Colors.Text.primary1)
                }
                .hidden(isButtonBusy)
                .overlay {
                    if isButtonBusy {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Colors.Icon.informative))
                    }
                }
            })
            .roundedBackground(with: Colors.Button.secondary, verticalPadding: 6, horizontalPadding: 12, radius: 10)
            .disabled(isButtonBusy)
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
