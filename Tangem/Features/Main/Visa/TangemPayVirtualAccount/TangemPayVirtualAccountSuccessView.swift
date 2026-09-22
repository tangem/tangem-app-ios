//
//  TangemPayVirtualAccountSuccessView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct TangemPayVirtualAccountSuccessView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountSuccessViewModel

    var body: some View {
        TangemPaySuccessView(
            model: .init(
                icon: DesignSystem.Icons.Success.regular20,
                title: Localization.tangempayBankTransferSuccessTitle,
                subtitle: Localization.tangempayBankTransferSuccessSubtitle,
                buttonTitle: Localization.commonClose,
                titleAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.virtualAccountSuccessTitle,
                buttonAccessibilityIdentifier: TangemPayAccessibilityIdentifiers.virtualAccountSuccessCloseButton
            ),
            action: viewModel.close
        )
    }
}
