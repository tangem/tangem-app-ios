//
//  WCTransactionSendLoadingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct WCTransactionSendLoadingView: View {
    @State private var requestIconIsRotating = false

    var body: some View {
        content
            .background(Colors.Background.tertiary)
            .frame(maxWidth: .infinity)
            .onAppear {
                requestIconIsRotating = true
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            icon
                .padding(.init(top: 8, leading: 16, bottom: 24, trailing: 16))

            VStack(spacing: 8) {
                Text(Localization.walletConnectSendingMultipleTx)
                    .style(Fonts.Bold.title3.weight(.semibold), color: Colors.Text.primary1)
                    .lineLimit(2)
                    .padding(.horizontal, 16)

                Text(LocalizedStringKey(Localization.walletConnectSendingMultipleExplanation))
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .lineLimit(6)
                    .padding(.init(top: 0, leading: 16, bottom: 50, trailing: 16))
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
    }

    private var icon: some View {
        Assets.Glyphs.load.image
            .resizable()
            .frame(width: 32, height: 32)
            .foregroundStyle(Colors.Icon.accent)
            .frame(width: 56, height: 56)
            .rotationEffect(.degrees(requestIconIsRotating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: requestIconIsRotating)
    }
}
