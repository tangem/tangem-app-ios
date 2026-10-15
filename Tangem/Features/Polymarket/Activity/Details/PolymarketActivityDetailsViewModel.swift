//
//  PolymarketActivityDetailsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket
import TangemPolymarketUI

final class PolymarketActivityDetailsViewModel: ObservableObject, Identifiable {
    let model: PolymarketActivityDetailsView.Model
    let canGoToPredict: Bool

    private let eventID: String?
    private weak var coordinator: PolymarketActivityDetailsRoutable?

    init(record: PolymarketActivityRecord, coordinator: PolymarketActivityDetailsRoutable) {
        model = .make(record: record)
        eventID = record.market?.event?.eventId.nilIfEmpty
        canGoToPredict = eventID != nil
        self.coordinator = coordinator
    }
}

// MARK: - View actions

extension PolymarketActivityDetailsViewModel {
    @MainActor
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .closeTapped:
            coordinator?.closeActivityDetails()
        case .goToPredictTapped:
            guard let eventID else { return }

            coordinator?.openActivityEvent(eventID: eventID)
        }
    }

    enum ViewAction {
        case closeTapped
        case goToPredictTapped
    }
}

// MARK: - Routing

protocol PolymarketActivityDetailsRoutable: AnyObject {
    @MainActor
    func closeActivityDetails()

    @MainActor
    func openActivityEvent(eventID: String)
}
