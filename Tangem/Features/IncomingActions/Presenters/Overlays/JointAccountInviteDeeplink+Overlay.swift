//
//  JointAccountInviteDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension JointAccountInviteDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard FeatureProvider.isAvailable(.jointAccounts) else {
            return nil
        }

        let coordinator = JointAccountJoinCoordinator(
            dismissAction: { context.dismiss() },
            popToRootAction: { _ in context.dismiss() }
        )
        coordinator.start(with: .init(inviteId: inviteId))

        // The flow brings its own navigation stack, and every one of its screens carries a close button.
        return .ready(context.cover(AnyView(JointAccountJoinCoordinatorView(coordinator: coordinator))))
    }
}
