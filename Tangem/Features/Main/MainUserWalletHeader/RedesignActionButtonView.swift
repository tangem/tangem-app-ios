//
//  RedesignActionButtonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct RedesignActionButtonView<ViewModel: ActionButtonViewModel>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        if viewModel.viewState != .unavailable {
            TangemMainActionButton(
                title: viewModel.model.title,
                icon: viewModel.model.icon,
                action: { viewModel.tap() },
                reasonTapWhenDisabled: viewModel.isTappableWhileDisabled ? { viewModel.showRestrictionReason() } : nil
            )
            .disabled(viewModel.isDimmed)
            .accessibilityIdentifier(viewModel.model.accessibilityIdentifier)
            .bindAlert($viewModel.alert)
        }
    }
}
