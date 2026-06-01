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
                .padding(.top, Constants.topGap)
                .padding(.bottom, Constants.bottomPadding)

        case .inlineList(let items):
            TokenDetailsActionRowsListView(items: items)
                .padding(.top, Constants.topGap)
                .padding(.bottom, Constants.bottomPadding)
        }
    }
}

private extension TokenDetailsActionsView {
    enum Constants {
        /// Design spec: 40pt absolute gap from the previous section's content to this section's content.
        /// Parent VStack already contributes its section spacing, so subtract it. Clamp to 0 if the
        /// parent spacing ever grows beyond the target gap.
        static let topGap: CGFloat = max(0, .unit(.x10) - TokenDetailsView.Constants.sectionSpacing)
        static let bottomPadding: CGFloat = .unit(.x2)
    }
}
