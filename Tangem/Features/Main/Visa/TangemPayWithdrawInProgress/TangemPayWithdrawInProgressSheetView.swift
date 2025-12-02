//
//  TangemPayWithdrawInProgressSheetView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayWithdrawInProgressSheetView: View {
    let viewModel: TangemPayWithdrawInProgressSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
            icon: .init(icon: Assets.clock32, overlay: Colors.Icon.secondary),
            title: Localization.tangempayCardDetailsWithdrawInProgressTitle,
            subtitle: Localization.tangempayCardDetailsWithdrawInProgressDescription,
            closeAction: viewModel.close,
            primaryButton: MainButton.Settings(
                title: Localization.commonGotIt,
                style: .secondary,
                action: viewModel.close
            )
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
