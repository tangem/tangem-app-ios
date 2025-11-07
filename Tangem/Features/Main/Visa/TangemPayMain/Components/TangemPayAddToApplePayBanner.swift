//
//  TangemPayAddToApplePayBanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPayAddToApplePayBanner: View {
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .frame(width: 48, height: 48)
                .foregroundStyle(Color.white.opacity(0.1))
                .overlay {
                    Assets.Visa.appleWallet.image
                }

            // [REDACTED_TODO_COMMENT]
            VStack(alignment: .leading, spacing: 4) {
                Text("Add your card to Apple Pay")
                    .style(Fonts.Bold.footnote, color: Colors.Text.constantWhite)
                Text("Set up Tangem Pay in a few taps and start paying with Apple Pay.")
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .multilineTextAlignment(.leading)
            .infinityFrame(axis: .horizontal, alignment: .leading)
        }
        .padding()
        .background {
            Rectangle()
                .fill(
                    // this is approximation of the background from the design
                    // the exact gradient parameters are not supported in SwiftUI
                    // [REDACTED_TODO_COMMENT]
                    RadialGradient(
                        gradient: Gradient(colors: [Color(hex: "#252934")!, Color(hex: "#12141E")!]),
                        center: UnitPoint(x: 0.1093, y: 0.7115),
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .background(.ultraThinMaterial)
                .cornerRadius(16)
        }
    }
}
