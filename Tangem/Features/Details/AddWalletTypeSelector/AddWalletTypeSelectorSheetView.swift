//
//  AddWalletTypeSelectorSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI

struct AddWalletTypeSelectorSheetView: View {
    let viewModel: AddWalletTypeSelectorSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                title: Localization.userWalletAddWallet,
                backgroundColor: DesignSystem.Color.bgSecondary,
                closeButtonAction: viewModel.onCloseTap
            )

            VStack(spacing: .zero) {
                Row(title: Localization.userWalletAddHardwareTitle, subtitle: Localization.userWalletAddHardwareDescription)
                    .start { iconView(DesignSystem.Icons.LogoTangem.regular20) }
                    .onTap(viewModel.onHardwareWalletTap)
                    .accessibilityIdentifier(DetailsAccessibilityIdentifiers.addWalletTypeHardwareButton)

                Row(title: Localization.userWalletAddMobileTitle, subtitle: Localization.userWalletAddMobileDescription)
                    .start { iconView(DesignSystem.Icons.GridPlus.regular20) }
                    .onTap(viewModel.onMobileWalletTap)
                    .accessibilityIdentifier(DetailsAccessibilityIdentifiers.addWalletTypeMobileButton)
            }
            .padding(.bottom, 8)
        }
        .floatingSheetConfiguration {
            $0.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            $0.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private func iconView(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconBrand)
            .padding(10)
            .background(DesignSystem.Color.bgStatusInfoSubtle)
            .clipShape(Circle())
    }
}
