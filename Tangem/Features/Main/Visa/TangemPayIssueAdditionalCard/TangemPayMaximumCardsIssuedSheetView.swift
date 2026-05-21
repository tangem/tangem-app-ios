//
//  TangemPayMaximumCardsIssuedSheetView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayMaximumCardsIssuedSheetView: View {
    let viewModel: TangemPayMaximumCardsIssuedSheetViewModel

    var body: some View {
        BottomSheetErrorContentView(
            title: viewModel.title,
            subtitle: viewModel.description,
            closeAction: viewModel.dismiss,
            primaryButton: viewModel.primaryButton
        )
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
