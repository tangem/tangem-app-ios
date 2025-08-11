//
//  AlertPresenterViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct TangemUIUtils.AlertBinder
import struct TangemUIUtils.ActionSheetBinder

final class AlertPresenterViewModel: ObservableObject {
    @Published var alert: AlertBinder?
    @Published var actionSheet: ActionSheetBinder?

    init() {}
}

// MARK: - AlertPresenter

extension AlertPresenterViewModel: AlertPresenter {
    func present(alert: AlertBinder) {
        Task { @MainActor in self.alert = alert }
    }

    func present(actionSheet: ActionSheetBinder) {
        Task { @MainActor in self.actionSheet = actionSheet }
    }

    func hideAlert() {
        Task { @MainActor in
            self.alert = nil
            self.actionSheet = nil
        }
    }
}
