//
//  JointAccountDeeplink+Overlay.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension JointAccountDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        guard FeatureProvider.isAvailable(.jointAccounts), entry == .members, let userWalletModel = findUserWalletModel() else {
            return nil
        }

        return .whenReady {
            guard let jointAccount = await findJointAccount(in: userWalletModel) else {
                return nil
            }

            jointAccount.userTokensManager.sync {}

            let coordinator = JointAccountManagementCoordinator(
                dismissAction: { context.dismiss() },
                popToRootAction: { _ in context.dismiss() }
            )
            coordinator.start(with: .members(jointAccount: jointAccount))

            return context.cover(AnyView(JointAccountManagementCoordinatorView(coordinator: coordinator)))
        }
    }
}
