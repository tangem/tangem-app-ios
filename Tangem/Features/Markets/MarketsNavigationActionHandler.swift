//
//  MarketsNavigationActionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MarketsViewModel {
    struct MarketsNavigationActionHandler {
        @Injected(\.overlayContentStateController) private var bottomSheetStateController: OverlayContentStateController
        @Injected(\.mainBottomSheetUIManager) private var mainBottomSheetUIManager: MainBottomSheetUIManager
        @Injected(\.appLockController) private var appLockController: AppLockController
        
        private let coordinator: MarketsRoutable
        private let bottomSheetPosition: () -> BottomSheetPosition
        private let searchAction: (String, Bool) -> Void
        
        init(
            coordinator: MarketsRoutable,
            bottomSheetPosition: @escaping () -> BottomSheetPosition,
            searchAction: @escaping (String, Bool) -> Void
        ) {
            self.coordinator = coordinator
            self.bottomSheetPosition = bottomSheetPosition
            self.searchAction = searchAction
        }
    }
}

extension MarketsViewModel.MarketsNavigationActionHandler {
    enum BottomSheetPosition {
        case unknown
        case expanded
        case collapsed
    }
}

extension MarketsViewModel.MarketsNavigationActionHandler {
    private func routeTokenChartAction(tokenName: String) -> Bool {
        let sheetPosition = bottomSheetPosition()
        
        switch sheetPosition {
        case .expanded:
            searchAction(tokenName, true)
            return true
            
        case .unknown:
            return false
            
        case .collapsed:
            bottomSheetStateController.expand()
            searchAction(tokenName, true)
            return true
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

// MARK: - NavigationActionHandling

extension MarketsViewModel.MarketsNavigationActionHandler: NavigationActionHandling {
    func routeIncommingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(let navigationAction) = action,
              !appLockController.isLocked,
              mainBottomSheetUIManager.isShown
        else {
            return false
        }
        
        switch navigationAction {
        case .markets:
            return routMarketsAction()
            
        case .tokenChart(let tokenName):
            return routeTokenChartAction(tokenName: tokenName)
            
        default:
            return false
        }
    }
}
