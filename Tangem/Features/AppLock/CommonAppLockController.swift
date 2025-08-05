//
//  CommonAppLockController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

class CommonAppLockController {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private let minimizedAppTimer = MinimizedAppTimer(interval: 5 * 60)
    private let startupProcessor = StartupProcessor()

    init() {}
}

extension CommonAppLockController: AppLockController {
    var isLocked: Bool {
        minimizedAppTimer.elapsed
    }

    func sceneDidEnterBackground() {
        if !userWalletRepository.isLocked {
            minimizedAppTimer.start()
        }
    }

    func sceneWillEnterForeground() {
        if minimizedAppTimer.elapsed {
            userWalletRepository.lock()
        } else {
            minimizedAppTimer.stop()
        }
    }

    func unlockApp() async -> UnlockResult {
        guard startupProcessor.shouldOpenAuthScreen else {
            return .openWelcome
        }

        guard let context = try? await UserWalletBiometricsUnlocker().unlock(),
              let userWalletModel = try? await userWalletRepository.unlock(with: .biometrics(context)) else {
            return .openAuth
        }

        minimizedAppTimer.stop()
        return .openMain(userWalletModel)
    }
}
