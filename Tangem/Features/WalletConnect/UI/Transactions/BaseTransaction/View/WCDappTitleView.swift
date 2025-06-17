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
    private let isLoading: Bool
    private let icons: [String]
    private let dappName: String
    private let dappUrl: String
    private let iconSideLength: CGFloat
    private let placeholderIconSideLength: CGFloat

    init(
        isLoading: Bool,
        proposal: Session.Proposal?,
        iconSideLength: CGFloat = 56,
        placeholderIconSideLength: CGFloat = 26
    ) {
        self.isLoading = isLoading
        icons = proposal?.proposer.icons ?? []
        dappName = proposal?.proposer.name ?? ""
        dappUrl = proposal?.proposer.url ?? ""
        self.iconSideLength = iconSideLength
        self.placeholderIconSideLength = placeholderIconSideLength
    }

    init(
        isLoading: Bool,
        sessionDappInfo: WalletConnectSavedSession.DAppInfo,
        iconSideLength: CGFloat = 56,
        placeholderIconSideLength: CGFloat = 26
    ) {
        self.isLoading = isLoading
        icons = sessionDappInfo.iconLinks
        dappName = sessionDappInfo.name
        dappUrl = sessionDappInfo.url
        self.iconSideLength = iconSideLength
        self.placeholderIconSideLength = placeholderIconSideLength
    }

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
                if let urlString = icons.last, let iconURL = URL(string: urlString) {
                    IconView(url: iconURL, size: .init(bothDimensions: iconSideLength))
                } else {
                    ZStack {
                        Colors.Icon.accent.opacity(0.1)
                            .frame(size: .init(bothDimensions: iconSideLength))
                            .cornerRadius(8, corners: .allCorners)
                        Assets.Glyphs.explore.image
                            .renderingMode(.template)
                            .foregroundStyle(Colors.Icon.accent)
                            .frame(size: .init(bothDimensions: placeholderIconSideLength))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if !dappName.isEmpty {
                        Text(dappName)
                            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    }

                    if dappUrl.isEmpty {
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
        .curve(.easeOutStandard, duration: duration)
    }
}
