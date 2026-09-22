//
//  JointAccountSupportedNetworksView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountSupportedNetworksView: View {
    let viewModel: JointAccountSupportedNetworksViewModel

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                title: Localization.commonSupportedNetworks,
                backgroundColor: DesignSystem.Color.bgSecondary,
                closeButtonAction: viewModel.onCloseTap
            )

            networks
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.contentVerticalPadding)

            gotItButton
                .padding(Constants.horizontalPadding)
        }
        .floatingSheetConfiguration {
            $0.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            $0.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var networks: some View {
        ViewThatFits(in: .vertical) {
            networksCard

            ScrollView(.vertical) {
                networksCard
            }
            .scrollBounceBehavior(.basedOnSize)
            .overlay(alignment: .bottom) {
                Fade(position: .bottom)
            }
        }
    }

    private var networksCard: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.networks) { network in
                networkRow(network)
            }
        }
        .background(DesignSystem.Color.bgTertiary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private func networkRow(_ network: JointAccountSupportedNetworksViewModel.NetworkViewData) -> some View {
        Row(title: network.name)
            .titleAccessory {
                Text(network.symbol)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
            }
            .start {
                NetworkIcon(
                    imageAsset: network.icon,
                    isActive: true,
                    isMainIndicatorVisible: false,
                    size: Constants.iconSize
                )
            }
    }

    private var gotItButton: some View {
        TangemUI.Button(
            label: Localization.commonGotIt,
            accessibilityLabel: Localization.commonGotIt,
            action: viewModel.onCloseTap
        )
        .styleType(.secondary(.default))
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}

// MARK: - Constants

private extension JointAccountSupportedNetworksView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let contentVerticalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let iconSize = CGSize(bothDimensions: 40)
    }
}

// MARK: - Previews

#Preview {
    JointAccountSupportedNetworksView(viewModel: JointAccountSupportedNetworksViewModel(coordinator: nil))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
