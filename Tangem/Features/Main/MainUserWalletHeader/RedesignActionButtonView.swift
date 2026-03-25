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
                buttonState: viewModel.viewState.buttonState,
                action: { viewModel.tap() }
            )
            .disabled(viewModel.viewState.isDisabledForInteraction)
            .accessibilityIdentifier(viewModel.model.accessibilityIdentifier)
            .bindAlert($viewModel.alert)
        }
    }
}

// MARK: - ActionButtonState mapping

private extension ActionButtonState {
    var buttonState: TangemMainActionButton.ButtonState {
        switch self {
        case .initial, .idle, .restricted:
            return .normal
        case .loading, .disabled:
            return .disabled
        case .unavailable:
            return .normal
        }
    }

    var isDisabledForInteraction: Bool {
        switch self {
        case .loading, .disabled:
            return true
        case .initial, .idle, .restricted, .unavailable:
            return false
        }
    }
}
