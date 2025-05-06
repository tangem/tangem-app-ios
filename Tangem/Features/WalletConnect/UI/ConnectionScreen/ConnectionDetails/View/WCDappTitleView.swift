//
//  WCDappTitleView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import ReownWalletKit

struct WCDappTitleView: View {
    let isLoading: Bool
    let proposal: Session.Proposal?

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            dappTitleStub
                .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.4)))
        } else {
            HStack(spacing: 16) {
                if let urlString = proposal?.proposer.icons.last, let iconURL = URL(string: urlString) {
                    IconView(url: iconURL, size: .init(bothDimensions: 56))
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let dappName = proposal?.proposer.name, !dappName.isEmpty {
                        Text(proposal?.proposer.name ?? "")
                            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    }

                    if let dappUrl = proposal?.proposer.url, !dappUrl.isEmpty {
                        Text(dappUrl)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }
                .multilineTextAlignment(.leading)
            }
            .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.4)))
        }
    }

    private var dappTitleStub: some View {
        HStack(spacing: 16) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(size: .init(bothDimensions: 56))
                .skeletonable(isShown: true, radius: 12)
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 119, height: 25)
                    .skeletonable(isShown: true, radius: 8)

                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 168, height: 18)
                    .skeletonable(isShown: true, radius: 8)
            }
        }
    }
}

// MARK: - UI Helpers

private extension WCDappTitleView {
    func makeDefaultAnimationCurve(duration: TimeInterval) -> Animation {
        .timingCurve(0.65, 0, 0.35, 1, duration: duration)
    }
}
