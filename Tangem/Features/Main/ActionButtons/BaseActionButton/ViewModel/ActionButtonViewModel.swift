//
//  ActionButtonViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUIUtils.AlertBinder

protocol ActionButtonViewModel: ObservableObject, Identifiable {
    var viewState: ActionButtonState { get }
    var model: ActionButtonModel { get }
    var alert: AlertBinder? { get set }

    @MainActor
    func tap()

    @MainActor
    func updateState(to state: ActionButtonState)
}

extension ActionButtonViewModel {
    // [REDACTED_INFO]: only the legacy `ActionButtonView` reads this; remove with that view (redesign uses `isDimmed`).
    var isDisabled: Bool {
        viewState == .disabled
    }

    var isDimmed: Bool {
        switch viewState {
        case .restricted, .loading, .disabled:
            return true
        case .initial, .idle, .unavailable:
            return false
        }
    }

    var isTappableWhileDisabled: Bool {
        if case .restricted = viewState {
            return true
        }
        return false
    }

    @MainActor
    func showRestrictionReason() {
        guard case .restricted(let reason) = viewState else { return }

        trackTapEvent()
        alert = .init(title: "", message: reason)
    }

    func trackTapEvent() {
        ActionButtonsAnalyticsService.trackActionButtonTap(button: model, state: viewState)
    }
}
