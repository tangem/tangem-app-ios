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
            row(
                title: Localization.commonCryptoAccount,
                subtitle: Localization.addCryptoAccountSubtitle,
                icon: DesignSystem.Icons.User.regular20,
                accessibilityIdentifier: AccountsAccessibilityIdentifiers.addAccountTypeSelectorCryptoAccountButton,
                action: viewModel.onCryptoAccountTap
            )

            row(
                title: Localization.commonJointAccount,
                subtitle: Localization.addJointAccountSubtitle,
                icon: DesignSystem.Icons.Users.regular20,
                accessibilityIdentifier: AccountsAccessibilityIdentifiers.addAccountTypeSelectorJointAccountButton,
                action: viewModel.onJointAccountTap
            )
        }
    }

    private func row(
        title: String,
        subtitle: String,
        icon: ImageType,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Row(title: title, subtitle: subtitle)
            .subtitleLineLimit(nil)
            .start { iconView(icon) }
            .onTap(action)
            .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func iconView(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .padding(10)
            .background(DesignSystem.Color.bgTransparentOnMaterialPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Previews

#Preview {
    AddAccountTypeSelectorView(
        viewModel: AddAccountTypeSelectorViewModel(
            userWalletConfig: UserWalletConfigStubs.walletV2Stub,
            coordinator: nil
        )
    )
}
