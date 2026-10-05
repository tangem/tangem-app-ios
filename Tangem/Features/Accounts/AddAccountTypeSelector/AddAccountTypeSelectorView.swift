//
//  AddAccountTypeSelectorView.swift
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
import TangemUIUtils

struct AddAccountTypeSelectorView: View {
    @ObservedObject var viewModel: AddAccountTypeSelectorViewModel

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                title: Localization.accountFormTitleCreate,
                backgroundColor: DesignSystem.Color.bgSecondary,
                closeButtonAction: viewModel.onCloseTap
            )

            VStack(spacing: 8) {
                Row(title: Localization.commonCryptoAccount, subtitle: Localization.addCryptoAccountSubtitle)
                    .subtitleLineLimit(nil)
                    .start { iconView(DesignSystem.Icons.User.regular20) }
                    .onTap(viewModel.onCryptoAccountTap)
                    .background(DesignSystem.Color.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityIdentifier(AccountsAccessibilityIdentifiers.addAccountTypeSelectorCryptoAccountButton)

                Row(title: Localization.commonJointAccount, subtitle: Localization.addJointAccountSubtitle)
                    .subtitleLineLimit(nil)
                    .start { iconView(DesignSystem.Icons.Users.regular20) }
                    .onTap(viewModel.onJointAccountTap)
                    .background(DesignSystem.Color.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityIdentifier(AccountsAccessibilityIdentifiers.addAccountTypeSelectorJointAccountButton)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .floatingSheetConfiguration {
            $0.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            $0.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private func iconView(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .padding(10)
            .background(DesignSystem.Color.bgTransparentSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Previews

#Preview {
    AddAccountTypeSelectorView(
        viewModel: AddAccountTypeSelectorViewModel(
            accountModelsManager: AccountModelsManagerMock(),
            userWalletConfig: UserWalletConfigStubs.walletV2Stub,
            coordinator: nil
        )
    )
}
