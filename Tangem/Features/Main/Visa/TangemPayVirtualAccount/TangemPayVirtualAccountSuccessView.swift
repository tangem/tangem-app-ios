//
//  TangemPayVirtualAccountSuccessView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct TangemPayVirtualAccountSuccessView: View {
    @ObservedObject var viewModel: TangemPayVirtualAccountSuccessViewModel

    var body: some View {
        StatusScreen(
            title: Localization.tangempayBankTransferSuccessTitle,
            description: Localization.tangempayBankTransferSuccessSubtitle,
            actionTitle: Localization.commonClose,
            action: viewModel.close
        )
        .appearance(.success)
    }
}
