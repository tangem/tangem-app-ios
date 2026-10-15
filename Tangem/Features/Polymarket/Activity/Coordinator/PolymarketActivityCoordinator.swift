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
import TangemUI

final class PolymarketActivityCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root ViewModels

    @Published private(set) var rootViewModel: PolymarketActivityViewModel?

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
            rootViewModel = PolymarketActivityViewModel(activityService: options.activityService, coordinator: self)
        }
    }
}

// MARK: - Options

extension PolymarketActivityCoordinator {
    struct Options {
        let activityService: PolymarketActivityService
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
}
