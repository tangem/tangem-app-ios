//
//  AddWalletSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct AddWalletSheetView: View {
    @ObservedObject var viewModel: AddWalletSheetViewModel

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .options:
                options
                    .transition(Animations.contentTransition)
            case .importWallet(let viewModel):
                MobileImportWalletView(viewModel: viewModel)
                    .transition(Animations.contentTransition)
            }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }
}

// MARK: - Subviews

private extension AddWalletSheetView {
    var options: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.options) { option in
                optionRow(for: option)
            }
        }
        .allowsHitTesting(!viewModel.isLoading)
    }

    func optionRow(for option: AddWalletSheetOption) -> some View {
        Row(title: option.title, subtitle: option.subtitle)
            .contentLead(.start)
            .start { Avatar(.icon(option.icon)) }
            .end { optionRowAccessory(for: option) }
            .onTap { viewModel.onOptionTap(option) }
    }

    @ViewBuilder
    func optionRowAccessory(for option: AddWalletSheetOption) -> some View {
        if viewModel.loadingOption == option {
            Loader()
                .loaderSize(.size20)
                .loaderColor(DesignSystem.Color.iconSecondary)
        } else {
            DesignSystem.Icons.ChevronRight.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconTertiary)
        }
    }
}

// MARK: - Navigation

extension AddWalletSheetView {
    static func navigation(for viewModel: AddWalletSheetViewModel) -> ModalNavigation {
        switch viewModel.state {
        case .options:
            ModalNavigation
                .title(viewModel.title, isCloseEnabled: !viewModel.isLoading)
                .onCloseButtonTap(viewModel.onCloseTap)
        case .importWallet(let importViewModel):
            ModalNavigation
                .title("", leading: .custom(.back(action: importViewModel.onBackTap)))
                .onCloseButtonTap(viewModel.onCloseTap)
        }
    }
}

// MARK: - Constants

private extension AddWalletSheetView {
    enum Animations {
        static let contentTransition = AnyTransition.asymmetric(
            insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
            removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
        )
    }
}
