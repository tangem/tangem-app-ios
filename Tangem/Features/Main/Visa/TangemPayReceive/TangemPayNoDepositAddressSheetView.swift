//
//  TangemPayNoDepositAddressSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayNoDepositAddressSheetView: View {
    let viewModel: TangemPayNoDepositAddressSheetViewModel

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            TangemPayPopupView(
                viewModel: TangemPayNoDepositAddressPopupViewModel(onClose: viewModel.close)
            )
        } else {
            legacyBody
        }
    }
}

private extension TangemPayNoDepositAddressSheetView {
    var legacyBody: some View {
        BottomSheetErrorContentView(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            closeAction: viewModel.close,
            primaryButton: viewModel.primaryButtonSettings
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
