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

final class AlertPresenterViewModel: ObservableObject {
    @Published var alert: AlertBinder?
}

// MARK: - AlertPresenter

extension AlertPresenterViewModel: AlertPresenter {
    func present(alert: AlertBinder) {
        Task { @MainActor in
            self.alert = alert
        }
    }

    func hideAlert() {
        Task { @MainActor in
            self.alert = nil
        }
    }
}
