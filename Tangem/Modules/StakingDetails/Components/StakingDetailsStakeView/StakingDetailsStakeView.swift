//
//  StakingDetailsStakeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct StakingDetailsStakeView: View {
    let data: StakingDetailsStakeViewData

    var body: some View {
        switch data.action {
        case .none:
            content

        case .some(let action):
            Button(action: action) {
                content
            }
        }
    }

    private var content: some View {
        HStack(spacing: .zero) {
            image

            FixedSpacer(width: 12)

            VStack(alignment: .leading, spacing: 4) {
                topLineView

                bottomLineView
            }
        }
        .lineLimit(1)
        .infinityFrame(axis: .horizontal)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var image: some View {
        switch data.icon {
        case .icon(let imageType, let color):
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)

                imageType.image
                    .renderingMode(.template)
                    .foregroundColor(color)
            }
        case .image(let url):
            IconView(url: url, size: CGSize(width: 36, height: 36))
        }
    }

    private var topLineView: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                Text(data.title)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                if data.inProgress {
                    Assets.pendingTxIndicator.image
                }
            }

            Spacer(minLength: 4)

            SensitiveText(data.balance.fiat)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
        }
    }

    @ViewBuilder
    private var bottomLineView: some View {
        HStack(alignment: .center, spacing: 0) {
            if let subtitle = data.subtitle {
                Text(subtitle)
                    .font(Fonts.Regular.caption1)
            }

            Spacer(minLength: 4)

            SensitiveText(data.balance.crypto)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }
}

// MARK: - Setupable

#Preview("SelectableStakingDetailsStakeView") {
    struct StakingValidatorPreview: View {
        var body: some View {
            VStack {
                GroupedSection(
                    [
                        StakingDetailsStakeViewData(
                            title: "InfStones",
                            icon: .image(url: URL(string: "https://assets.stakek.it/validators/infstones.png")!),
                            inProgress: true,
                            subtitleType: .active(apr: "3,5%"),
                            balance: .init(crypto: "543 USD", fiat: "5 SOL"),
                            action: {}
                        ),
                        StakingDetailsStakeViewData(
                            title: "Coinbase",
                            icon: .image(url: URL(string: "https://assets.stakek.it/validators/coinbase.png")!),
                            inProgress: true,
                            subtitleType: .active(apr: "3,5%"),
                            balance: .init(crypto: "543 USD", fiat: "5 SOL"),
                            action: {}
                        ),
                        StakingDetailsStakeViewData(
                            title: "Binance",
                            icon: .image(url: URL(string: "https://assets.stakek.it/validators/infstones.png")!),
                            inProgress: false,
                            subtitleType: .active(apr: "3,5%"),
                            balance: .init(crypto: "543 USD", fiat: "5 SOL"),
                            action: .none
                        ),
                    ]
                ) {
                    StakingDetailsStakeView(data: $0)
                }
                .padding()
            }
            .background(Colors.Background.secondary.ignoresSafeArea())
        }
    }

    return StakingValidatorPreview()
}
