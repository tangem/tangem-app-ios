//
//  InformationHiddenBalancesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

// [REDACTED_TODO_COMMENT]
final class InformationHiddenBalancesViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: InformationHiddenBalancesRoutable

    init(
        coordinator: InformationHiddenBalancesRoutable
    ) {
        self.coordinator = coordinator
    }

    func userDidRequestCloseView() {
        coordinator.closeInformationHiddenBalances()
    }

    func userDidRequestDoNotShowAgain() {
        coordinator.closeInformationHiddenBalances()
    }
}
