//
//  MarketsNavigationActionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsNavigationActionHandler {
    @Injected(\.overlayContentStateController) private var bottomSheetStateController: OverlayContentStateController
    @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager

    private let coordinator: MarketsRoutable
    private let bottomSheetPosition: () -> BottomSheetPosition

    init(coordinator: MarketsRoutable, bottomSheetPosition: @escaping () -> BottomSheetPosition) {
        self.coordinator = coordinator
        self.bottomSheetPosition = bottomSheetPosition
    }
}

extension MarketsNavigationActionHandler {
    enum BottomSheetPosition {
        case unknown
        case expanded
        case collapsed
    }
}

extension MarketsNavigationActionHandler: NavigationActionHandling {
    func routeIncommingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(let navigationAction) = action,
              mainBottomSheetUIManager.isShown
        else {
            return false
        }

        switch navigationAction {
        case .markets:
            return routMarketsAction()

        case .tokenChart(let tokenName):
            return false

        default:
            return false
        }
    }

    private func routMarketsAction() -> Bool {
        if case .collapsed = bottomSheetPosition() {
            bottomSheetStateController.expand()
            return true
        }

        return false
    }
}
