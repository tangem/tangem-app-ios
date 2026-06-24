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
        case issued(cardNumberEnd: String)
        case issuing
        case replacing
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
        case .issuing, .replacing:
            Assets.Visa.chipIssuing.image
                .resizable()
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .issued:
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 6)
                .foregroundStyle(.white)
                .frame(width: 12, height: 12)
        case .issuing, .replacing:
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
        if case .issued(let cardNumberEnd) = state {
            Text(cardNumberEnd)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 12, alignment: .trailing)
                .offset(x: 0, y: 23)
        }
    }
}

// MARK: - Previews

#Preview {
    HStack(spacing: 8) {
        TangemPaySmallCardViewRedesigned(state: .issued(cardNumberEnd: "9092"))
        TangemPaySmallCardViewRedesigned(state: .issuing)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
