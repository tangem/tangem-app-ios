//
//  ActionButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ActionButtonsView: View {
    @ObservedObject var viewModel: ActionButtonsViewModel

    var body: some View {
        HStack(spacing: 8) {
            if let buyActionButtonViewModel = viewModel.buyActionButtonViewModel {
                ActionButtonView(viewModel: buyActionButtonViewModel)
            }
            ActionButtonView(viewModel: viewModel.swapActionButtonViewModel)
            ActionButtonView(viewModel: viewModel.sellActionButtonViewModel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
