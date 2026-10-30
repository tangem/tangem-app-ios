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
import TangemUIUtils

struct JointAccountSupportedNetworksView: View {
    let viewModel: JointAccountSupportedNetworksViewModel

    var body: some View {
        networks
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.contentVerticalPadding)
            .footer { Footer(.buttons(primary: gotItButton)).showFade() }
    }

    private var networks: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.networks) { network in
                networkRow(network)
            }
        }
        .roundedBackground(
            with: DesignSystem.Color.bgTransparentOnMaterialPrimary,
            padding: .zero,
            radius: Constants.cornerRadius
        )
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

    private var gotItButton: TangemUI.Button {
        TangemUI.Button(
            label: Localization.commonGotIt,
            accessibilityLabel: Localization.commonGotIt,
            action: viewModel.onCloseTap
        )
        .styleType(.secondary(.default))
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
    Color.clear.modal(isPresented: .constant(true), navigation: .title(Localization.commonSupportedNetworks)) {
        JointAccountSupportedNetworksView(viewModel: JointAccountSupportedNetworksViewModel(coordinator: nil))
    }
}
