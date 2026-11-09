//
//  PolymarketOrderPresenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class PolymarketOrderPresenter: ObservableObject {
    @Published private(set) var presentation: Presentation?

    weak var mainCoordinator: PolymarketCoordinator?

    private var afterDismiss: (() -> Void)?

    var order: PolymarketOrderCoordinator? {
        presentation?.order
    }

    func present(_ coordinator: PolymarketOrderCoordinator, from host: AnyObject?) {
        presentation = Presentation(order: coordinator, hostID: host.map(ObjectIdentifier.init))
    }

    func dismiss() {
        presentation = nil
    }

    func dismiss(presentedFrom host: AnyObject) {
        guard presentation?.hostID == ObjectIdentifier(host) else { return }

        afterDismiss = nil
        presentation = nil
    }

    func runAfterDismiss(_ action: @escaping () -> Void) {
        afterDismiss = action
    }

    func didDismiss() {
        let action = afterDismiss
        afterDismiss = nil

        guard let action else { return }

        DispatchQueue.main.async(execute: action)
    }

    func binding(for host: AnyObject?) -> Binding<PolymarketOrderCoordinator?> {
        let hostID = host.map(ObjectIdentifier.init)

        return Binding(
            get: { [weak self] in
                guard let presentation = self?.presentation, presentation.hostID == hostID else { return nil }

                return presentation.order
            },
            set: { [weak self] value in
                guard value == nil, let self, presentation?.hostID == hostID else { return }

                presentation = nil
            }
        )
    }
}

// MARK: - Presentation

extension PolymarketOrderPresenter {
    struct Presentation {
        let order: PolymarketOrderCoordinator
        let hostID: ObjectIdentifier?
    }
}
