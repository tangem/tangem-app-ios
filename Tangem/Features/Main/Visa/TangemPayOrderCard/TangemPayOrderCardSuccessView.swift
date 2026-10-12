//
//  TangemPayOrderCardSuccessView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct TangemPayOrderCardSuccessView: View {
    @ObservedObject var viewModel: TangemPayOrderCardSuccessViewModel

    var body: some View {
        StatusScreen(
            title: viewModel.title,
            description: viewModel.deliveryNote,
            actionTitle: Localization.tangempayOrderSuccessShowCard,
            action: viewModel.showCard
        )
        .appearance(.success)
        .footerCaption(viewModel.emailNote)
        .topNavigation(leading: .none)
    }
}
