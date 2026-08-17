//
//  WelcomeV2Coordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

final class WelcomeV2Coordinator: CoordinatorObject {
    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: WelcomeV2ViewModel?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug("WelcomeV2Coordinator deinit")
    }

    func start(with options: Options) {
        rootViewModel = WelcomeV2ViewModel(coordinator: self)
    }
}

// MARK: - Options

extension WelcomeV2Coordinator {
    struct Options {}

    typealias OutputOptions = WelcomeCoordinator.OutputOptions
}

// MARK: - WelcomeV2Routable

extension WelcomeV2Coordinator: WelcomeV2Routable {}
