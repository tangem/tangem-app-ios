//
//  PolymarketActivityCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit
import TangemPolymarket
import TangemUI

final class PolymarketActivityCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketActivityViewModel?

    // MARK: - Child ViewModels

    @Published var destination: Destination?
    @Published var details: PolymarketActivityDetailsViewModel?

    private var onOrderPlaced: (@MainActor (PolymarketOrderIndexing) -> Void)?
    private var onRegionWarning: (() -> Void)?
    private weak var eventBuilder: PolymarketEventDetailsBuilder?

    // MARK: - Init

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        onOrderPlaced = options.onOrderPlaced
        onRegionWarning = options.onRegionWarning
        eventBuilder = options.eventBuilder

        Task { @MainActor in
            rootViewModel = PolymarketActivityViewModel(activityService: options.activityService, coordinator: self)
        }
    }
}

// MARK: - Options

extension PolymarketActivityCoordinator {
    struct Options {
        let activityService: PolymarketActivityService
        let onOrderPlaced: @MainActor (PolymarketOrderIndexing) -> Void
        let onRegionWarning: () -> Void
        let eventBuilder: PolymarketEventDetailsBuilder
    }

    enum Destination {
        case eventDetails(PolymarketEventDetailsCoordinator)
    }
}

// MARK: - PolymarketActivityRoutable protocol conformance

extension PolymarketActivityCoordinator: PolymarketActivityRoutable {
    func closeActivity() {
        dismiss()
    }

    func shareActivityExport(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    @MainActor
    func openActivityDetails(record: PolymarketActivityRecord) {
        details = PolymarketActivityDetailsViewModel(record: record, coordinator: self)
    }
}

// MARK: - PolymarketActivityDetailsRoutable protocol conformance

extension PolymarketActivityCoordinator: PolymarketActivityDetailsRoutable {
    @MainActor
    func closeActivityDetails() {
        details = nil
    }

    @MainActor
    func openActivityEvent(eventID: String) {
        guard let eventBuilder, let onOrderPlaced else { return }

        destination = .eventDetails(eventBuilder.makeEventDetailsCoordinator(
            eventID: eventID,
            category: nil,
            onOrderPlaced: { [weak self] indexing in
                onOrderPlaced(indexing)
                self?.refreshActivity(after: indexing)
            },
            onRegionWarning: { [weak self] in self?.onRegionWarning?() },
            onClose: { [weak self] in self?.popToActivity() }
        ))
        details = nil
    }
}

// MARK: - Navigation

extension PolymarketActivityCoordinator {
    @MainActor
    private func refreshActivity(after indexing: PolymarketOrderIndexing) {
        Task { @MainActor [weak self] in
            _ = await indexing.value
            await self?.rootViewModel?.refresh()
        }
    }

    func popToActivity() {
        destination = nil
    }
}
