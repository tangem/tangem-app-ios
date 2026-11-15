//
//  UserWalletLinkSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct UserWalletLinkSheetView: View {
    @ObservedObject var viewModel: UserWalletLinkSheetViewModel

    var body: some View {
        ModalStatus(.warning, title: viewModel.title, description: viewModel.description)
            .footer { Footer(.signingButton(linkButton)) }
            .safeAreaInset(edge: .top, spacing: .zero) {
                FloatingSheetNavigationBarView(closeButtonAction: viewModel.close)
            }
            .floatingSheetConfiguration { configuration in
                configuration.backgroundInteractionBehavior = .tapToDismiss
            }
    }

    private var linkButton: SigningActionButtonView {
        SigningActionButtonView(
            type: viewModel.signingButtonType,
            title: viewModel.buttonTitle,
            isLoading: viewModel.isLinking,
            isDisabled: false,
            action: viewModel.link
        )
    }
}
