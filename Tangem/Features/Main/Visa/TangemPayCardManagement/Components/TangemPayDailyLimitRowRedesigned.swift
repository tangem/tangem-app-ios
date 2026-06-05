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
        HStack(spacing: DesignSystem.Tokens.Spacing.s150) {
            icon

            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.tangempayCardPageDailyLimitTitle)
                    .font(DesignSystem.Tokens.Font.Body.medium)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Text.secondary)

                value
            }

            Spacer(minLength: DesignSystem.Tokens.Spacing.s150)

            trailing
        }
        .padding(DesignSystem.Tokens.Spacing.s200)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Tokens.Theme.Bg.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._300, style: .continuous))
    }

    private var icon: some View {
        DesignSystem.Icons.Gauge.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Tokens.Theme.Icon.Status.info)
            .frame(width: DesignSystem.Tokens.Size.s250, height: DesignSystem.Tokens.Size.s250)
            .frame(width: DesignSystem.Tokens.Size.s500, height: DesignSystem.Tokens.Size.s500)
            .background(DesignSystem.Tokens.Theme.Bg.Status.infoSubtle)
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
            .font(DesignSystem.Tokens.Font.Body.medium)
            .foregroundStyle(DesignSystem.Tokens.Theme.Text.primary)
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

#if DEBUG
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
    .padding(DesignSystem.Tokens.Spacing.s200)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Tokens.Theme.Bg.primary)
}
#endif // DEBUG
