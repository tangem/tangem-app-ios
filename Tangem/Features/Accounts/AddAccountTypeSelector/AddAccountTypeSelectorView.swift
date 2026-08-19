//
//  AddAccountTypeSelectorView.swift
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
                    .start { iconView(Assets.Accounts.user) }
                    .onTap(viewModel.onCryptoAccountTap)
                    .background(DesignSystem.Color.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Row(title: Localization.commonJointAccount, subtitle: Localization.addJointAccountSubtitle)
                    .subtitleLineLimit(nil)
                    .start { iconView(Assets.Accounts.family) }
                    .onTap(viewModel.onJointAccountTap)
                    .background(DesignSystem.Color.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            .resizable()
            .frame(size: CGSize(bothDimensions: 20))
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .padding(10)
            .background(DesignSystem.Color.bgOpaqueSecondary)
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
