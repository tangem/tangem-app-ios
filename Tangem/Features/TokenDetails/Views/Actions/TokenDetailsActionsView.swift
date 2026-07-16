//
//  TokenDetailsActionsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TokenDetailsActionsView: View {
    @ObservedObject var viewModel: TokenDetailsActionsViewModel

    var body: some View {
        switch viewModel.mode {
        case .hidden:
            EmptyView()

        case .buttonsRow(let buttons):
            TokenDetailsActionsButtonsRowView(buttons: buttons)
                .padding(.bottom, Constants.bottomPadding)

        case .inlineList(let items):
            TokenDetailsActionRowsListView(items: items)
                .padding(.bottom, Constants.bottomPadding)
        }
    }
}

private extension TokenDetailsActionsView {
    enum Constants {
        static let bottomPadding: CGFloat = .unit(.x2)
    }
}
