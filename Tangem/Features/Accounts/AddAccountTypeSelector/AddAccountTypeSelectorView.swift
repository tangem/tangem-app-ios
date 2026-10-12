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

            AddAccountTypeSelectorContentView(viewModel: viewModel)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
        .floatingSheetConfiguration {
            $0.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            $0.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

struct AddAccountTypeSelectorContentView: View {
    @ObservedObject var viewModel: AddAccountTypeSelectorViewModel
    private let style: Style

    init(viewModel: AddAccountTypeSelectorViewModel, style: Style = .cards) {
        self.viewModel = viewModel
        self.style = style
    }

    var body: some View {
        VStack(spacing: style.rowSpacing) {
            row(
                title: Localization.commonCryptoAccount,
                subtitle: Localization.addCryptoAccountSubtitle,
                icon: DesignSystem.Icons.User.regular20,
                action: viewModel.onCryptoAccountTap
            )

            row(
                title: Localization.commonJointAccount,
                subtitle: Localization.addJointAccountSubtitle,
                icon: DesignSystem.Icons.Users.regular20,
                action: viewModel.onJointAccountTap
            )
        }
    }

    private func row(title: String, subtitle: String, icon: ImageType, action: @escaping () -> Void) -> some View {
        Row(title: title, subtitle: subtitle)
            .subtitleLineLimit(nil)
            .start { iconView(icon) }
            .onTap(action)
            .background(style.rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func iconView(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .padding(10)
            .background(style.iconBackground)
            .clipShape(RoundedRectangle(cornerRadius: style.iconCornerRadius, style: .continuous))
    }
}

extension AddAccountTypeSelectorContentView {
    enum Style {
        case cards
        case modal

        fileprivate var rowSpacing: CGFloat {
            switch self {
            case .cards: 8
            case .modal: 0
            }
        }

        fileprivate var rowBackground: Color {
            switch self {
            case .cards: DesignSystem.Color.bgTertiary
            case .modal: .clear
            }
        }

        fileprivate var iconBackground: Color {
            switch self {
            case .cards: DesignSystem.Color.bgTransparentSecondary
            case .modal: DesignSystem.Color.bgTransparentOnMaterialPrimary
            }
        }

        fileprivate var iconCornerRadius: CGFloat {
            switch self {
            case .cards: 8
            case .modal: 12
            }
        }
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
