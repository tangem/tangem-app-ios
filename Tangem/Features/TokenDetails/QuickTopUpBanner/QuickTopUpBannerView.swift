//
//  QuickTopUpBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct QuickTopUpBannerView: View {
    @ObservedObject var viewModel: QuickTopUpBannerViewModel

    var body: some View {
        if viewModel.isVisible {
            VStack(alignment: .leading, spacing: 16) {
                Label(Localization.quickTopUpTitle, systemImage: "bolt.fill")
                    .style(Fonts.Bold.headline, color: Color.Tangem.Text.Neutral.primary)

                HStack(spacing: 8) {
                    ForEach(viewModel.chips) { chip in
                        SwiftUI.Button {
                            viewModel.onChipSelected(chip.id)
                        } label: {
                            Text(chip.title)
                                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                                .lineLimit(1)
                                .padding(.horizontal, Constants.chipHorizontalPadding)
                                .padding(.vertical, Constants.chipVerticalPadding)
                                .frame(height: Constants.chipHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: Constants.chipCornerRadius, style: .continuous)
                                        .fill(Color.Tangem.Button.backgroundPrimaryInverted)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glowBorder(effect: .bannerMagic)
        }
    }
}

// MARK: - Constants

private extension QuickTopUpBannerView {
    enum Constants {
        static let chipHeight: CGFloat = 36
        static let chipCornerRadius: CGFloat = 24
        static let chipHorizontalPadding: CGFloat = 16
        static let chipVerticalPadding: CGFloat = 8
    }
}
