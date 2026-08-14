//
//  TangemPayOtherNetworksSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct TangemPayOtherNetworksSheetView: View {
    let viewModel: TangemPayOtherNetworksSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            header
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            content
                .padding(.horizontal, 34)
                .padding(.top, 32)
                .padding(.bottom, 40)

            closeButton
                .padding(16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

private extension TangemPayOtherNetworksSheetView {
    var header: some View {
        BottomSheetHeaderView(title: Localization.tangempayOtherNetworksHeader, trailing: {
            TangemUI.Button(
                icon: DesignSystem.Icons.Cross.regular20,
                accessibilityLabel: Localization.commonClose,
                action: viewModel.close
            )
            .size(.x11)
            .styleType(.material(.glass))
        })
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
    }

    var content: some View {
        VStack(spacing: 24) {
            icon

            texts
        }
    }

    var icon: some View {
        DesignSystem.Icons.Info.regular28.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 28, height: 28)
            .foregroundStyle(DesignSystem.Color.iconStatusInfo)
            .frame(width: 80, height: 80)
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
    }

    var texts: some View {
        VStack(spacing: 8) {
            Text(Localization.tangempayOtherNetworksTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.tangempayOtherNetworksSubtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    var closeButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.commonClose),
            accessibilityLabel: Localization.commonClose,
            action: viewModel.close
        )
        .size(.x12)
        .styleType(.secondary)
        .horizontalLayout(.infinity)
    }
}
