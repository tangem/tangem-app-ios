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
        
        init(coordinator: MarketsRoutable, bottomSheetPosition: @escaping () -> BottomSheetPosition) {
            self.coordinator = coordinator
            self.bottomSheetPosition = bottomSheetPosition
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
    private func routeTokenChartAction(tokenSymbol: String, tokenId: String) -> Bool {
        let position = bottomSheetPosition()
        
        guard position != .unknown else {
            return false
        }
        
        if position == .collapsed {
            bottomSheetStateController.expand()
        }
        
        coordinator.openMarketsTokenDetails(tokenSymbol: tokenSymbol, tokenId: tokenId)
        return true
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
            
        case .tokenChart(let tokenSymbol, let tokenId):
            return routeTokenChartAction(tokenSymbol: tokenSymbol, tokenId: tokenId)
            
        default:
            return false
        }
    }
}
