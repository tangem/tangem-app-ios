//
//  PolymarketPositionDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket
import TangemPolymarketUI

final class PolymarketPositionDetailsViewModel: ObservableObject, Identifiable {
    @Published var hint: PolymarketPositionHintSheetView.Model?

    private(set) lazy var model: PolymarketPositionDetailsView.Model = .make(
        position: position,
        onClosePosition: { [weak self] in self?.coordinator?.closePositionDetails() },
        onBuy: { [weak self] in self?.coordinator?.closePositionDetails() },
        onHint: { [weak self] hint in self?.hint = hint }
    )

    private let position: PolymarketPosition
    private weak var coordinator: PolymarketPositionDetailsRoutable?

    init(position: PolymarketPosition, coordinator: PolymarketPositionDetailsRoutable) {
        self.position = position
        self.coordinator = coordinator
    }

    func onCloseTap() {
        coordinator?.closePositionDetails()
    }
}
