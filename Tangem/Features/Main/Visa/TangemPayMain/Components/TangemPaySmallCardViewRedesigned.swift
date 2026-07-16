//
//  TangemPaySmallCardViewRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPaySmallCardViewRedesigned: View {
    enum State {
        case issued(cardNumberEnd: String, isFrozen: Bool)
        case issuing
        case replacing
        /// It's used when user requested to issue the card but don't have money on account to do that.
        /// For example select paid plan after onboarding
        case ghost
    }

    let state: State

    var body: some View {
        ZStack(alignment: .topLeading) {
            background

            icon
                .offset(x: 3, y: 2)

            Assets.Visa.logo.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 8)
                .offset(x: 28, y: 4)

            cardNumber
        }
        .frame(width: 56, height: 40, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch state {
        case .issued:
            Assets.Visa.chipIssued.image
                .resizable()
        case .issuing, .replacing, .ghost:
            Assets.Visa.chipIssuing.image
                .resizable()
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .issued(_, let isFrozen):
            if isFrozen {
                DesignSystem.Icons.Snowflake.regular16.image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "cloud.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 6)
                    .foregroundStyle(.white)
                    .frame(width: 12, height: 12)
            }
        case .issuing, .replacing, .ghost:
            DesignSystem.Icons.Clock.regular16.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var cardNumber: some View {
        switch state {
        case .issued(let cardNumberEnd, _):
            numberText(cardNumberEnd)
        case .ghost:
            numberText("0000")
        case .issuing, .replacing:
            EmptyView()
        }
    }

    private func numberText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 50, height: 12, alignment: .trailing)
            .offset(x: 0, y: 23)
    }
}

// MARK: - Previews

#Preview {
    HStack(spacing: 8) {
        TangemPaySmallCardViewRedesigned(state: .issued(cardNumberEnd: "9092", isFrozen: false))
        TangemPaySmallCardViewRedesigned(state: .issued(cardNumberEnd: "9092", isFrozen: true))
        TangemPaySmallCardViewRedesigned(state: .issuing)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
