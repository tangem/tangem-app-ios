//
//  TangemPayIssuingCardDetailsViewRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayIssuingCardDetailsViewRedesigned: View {
    let isGhost: Bool

    var body: some View {
        cardArt.image
            .resizable()
            .aspectRatio(Constants.plasticCardStandardWidthToHeightRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }

    private var cardArt: ImageType {
        isGhost ? Assets.Visa.cardGhost : Assets.Visa.cardIssuing
    }
}

private extension TangemPayIssuingCardDetailsViewRedesigned {
    enum Constants {
        static let plasticCardStandardWidthToHeightRatio = 1.586
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        TangemPayIssuingCardDetailsViewRedesigned(isGhost: false)
        TangemPayIssuingCardDetailsViewRedesigned(isGhost: true)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
