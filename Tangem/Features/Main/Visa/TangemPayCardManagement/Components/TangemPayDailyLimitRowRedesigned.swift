//
//  TangemPayDailyLimitRowRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct TangemPayDailyLimitRowRedesigned: View {
    let state: TangemPayDailyLimitState
    let isFrozen: Bool
    let changeAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.tangempayCardPageDailyLimitTitle)
                    .font(token: DesignSystem.Font.bodyMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)

                value
            }

            Spacer(minLength: 12)

            trailing
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var icon: some View {
        DesignSystem.Icons.Gauge.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconStatusInfo)
            .frame(width: 40, height: 40)
            .background(DesignSystem.Color.bgStatusInfoSubtle)
            .clipShape(Circle())
    }

    @ViewBuilder
    private var value: some View {
        let text: String = {
            if case .loaded(let limit) = state {
                return limit.currentLimit
            }
            return "—"
        }()

        Text(text)
            .font(token: DesignSystem.Font.bodyMediumToken)
            .foregroundStyle(DesignSystem.Color.textPrimary)
            .lineLimit(1)
    }

    @ViewBuilder
    private var trailing: some View {
        switch state {
        case .loaded:
            if !isFrozen {
                TangemButtonV2(
                    label: AttributedString(Localization.commonEdit),
                    accessibilityLabel: Localization.commonEdit,
                    action: changeAction
                )
                .size(.x10)
                .styleType(.secondary)
            }
        case .loading:
            ProgressView()
                .progressViewStyle(.circular)
        case .error:
            EmptyView()
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 12) {
        TangemPayDailyLimitRowRedesigned(state: .loading, isFrozen: false, changeAction: {})
        TangemPayDailyLimitRowRedesigned(
            state: .loaded(TangemPayDailyLimit(currentLimit: "$50,000")),
            isFrozen: false,
            changeAction: {}
        )
        TangemPayDailyLimitRowRedesigned(
            state: .loaded(TangemPayDailyLimit(currentLimit: "$50,000")),
            isFrozen: true,
            changeAction: {}
        )
        TangemPayDailyLimitRowRedesigned(state: .error, isFrozen: false, changeAction: {})
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
