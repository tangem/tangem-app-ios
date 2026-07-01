//
//  RedesignedTokenAlertReceiveAssetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct RedesignedTokenAlertReceiveAssetsView: View {
    @ObservedObject var viewModel: TokenAlertReceiveAssetsViewModel

    var body: some View {
        VStack(spacing: .zero) {
            content

            gotItButton
                .padding(16)
        }
        .onAppear(perform: viewModel.onViewAppear)
    }

    private var content: some View {
        VStack(spacing: 32) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(bothDimensions: 72)
            )

            textBlock
        }
        .padding(16)
    }

    private var textBlock: some View {
        VStack(spacing: 8) {
            VStack(spacing: .zero) {
                Text(Localization.domainReceiveAssetsOnboardingTitle)
                    .lineLimit(2)

                Text(Localization.domainReceiveAssetsOnboardingNetworkName(viewModel.networkName))
            }
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.domainReceiveAssetsOnboardingDescription)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
    }

    private var gotItButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.commonGotIt),
            accessibilityLabel: Localization.commonGotIt,
            action: viewModel.onGotItTapAction
        )
        .size(.x12)
        .styleType(.secondary)
        .horizontalLayout(.infinity)
    }
}
