//
//  PolymarketMyPositionsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket
import TangemStories

final class PolymarketMyPositionsCoordinator: CoordinatorObject {
    @Injected(\.tangemStoriesPresenter) private var tangemStoriesPresenter: any TangemStoriesPresenter

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketMyPositionsViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            rootViewModel = PolymarketMyPositionsViewModel(
                tab: options.tab,
                positionsService: options.positionsService,
                coordinator: self
            )
        }
    }
}

// MARK: - Options

extension PolymarketMyPositionsCoordinator {
    struct Options {
        let tab: PolymarketPositionsTab
        let positionsService: PolymarketPositionsService
    }

    enum Destination {
        case positionDetails(PolymarketPositionDetailsViewModel)
    }
}

// MARK: - PolymarketMyPositionsRoutable protocol conformance

extension PolymarketMyPositionsCoordinator: PolymarketMyPositionsRoutable {
    func closeMyPositions() {
        dismiss()
    }

    @MainActor
    func openHowItWorks() {
        tangemStoriesPresenter.present(
            story: .polymarketOnboarding(.initialWithoutImages),
            analyticsSource: .predictions,
            presentCompletion: {}
        )
    }

    func openPositionDetails(position: PolymarketPosition) {
        destination = .positionDetails(PolymarketPositionDetailsViewModel(position: position, coordinator: self))
    }
}

// MARK: - PolymarketPositionDetailsRoutable protocol conformance

extension PolymarketMyPositionsCoordinator: PolymarketPositionDetailsRoutable {
    func closePositionDetails() {
        destination = nil
    }
}
