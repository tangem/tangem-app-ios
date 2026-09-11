//
//  TangemPayCashbackDetailContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayCashbackDetailContentView: View {
    let state: TangemPayCashbackDetailState
    let reloadAction: () -> Void
    let rateCardAction: () -> Void
    let accrualsCardAction: () -> Void

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary
                .ignoresSafeArea()

            if isEmptyState {
                TangemPayCashbackEmptyGlowBackground()
            }

            switch state {
            case .idle, .loading:
                TangemPayCashbackDetailSkeletonView()
                    .transition(.opacity)
            case .loaded(let data):
                TangemPayCashbackDetailLoadedView(
                    data: data,
                    rateCardAction: rateCardAction,
                    accrualsCardAction: accrualsCardAction
                )
                .transition(.opacity)
            case .failed:
                failedView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: state)
    }
}

// MARK: - State Views

private extension TangemPayCashbackDetailContentView {
    var isEmptyState: Bool {
        guard case .loaded(let data) = state else {
            return false
        }

        return data.isEmpty
    }

    var failedView: some View {
        VStack(spacing: 12) {
            TangemUI.Button(
                icon: DesignSystem.Icons.ArrowRefresh.regular20,
                accessibilityLabel: nil,
                action: reloadAction
            )
            .size(.x10)
            .styleType(.default)

            Text(Localization.tangempayCashbackErrorTitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Cashback Loaded") {
    TangemPayCashbackDetailContentView(
        state: .loaded(.preview),
        reloadAction: {},
        rateCardAction: {},
        accrualsCardAction: {}
    )
}

#Preview("Cashback Empty") {
    TangemPayCashbackDetailContentView(
        state: .loaded(.previewEmpty),
        reloadAction: {},
        rateCardAction: {},
        accrualsCardAction: {}
    )
}

#Preview("Cashback Loading") {
    TangemPayCashbackDetailContentView(
        state: .loading,
        reloadAction: {},
        rateCardAction: {},
        accrualsCardAction: {}
    )
}

#Preview("Cashback Failed") {
    TangemPayCashbackDetailContentView(
        state: .failed,
        reloadAction: {},
        rateCardAction: {},
        accrualsCardAction: {}
    )
}
#endif
