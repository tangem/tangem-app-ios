//
//  MobileFinishActivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MobileFinishActivationManager {
    typealias Activation = (UserWalletModel) -> Void

    private var userWalletId: UserWalletId?
    private var onActivation: Activation?
    private var isObservationFinished: Bool = false
    private var walletModelsSubscription: AnyCancellable?

    func observe(userWalletId: UserWalletId, onActivation: @escaping Activation) {
        self.userWalletId = userWalletId
        self.onActivation = onActivation
        isObservationFinished = false
    }

    func activateIfNeeded(userWalletModel: UserWalletModel) {
        guard
            let userWalletId, onActivation != nil,
            userWalletId == userWalletModel.userWalletId,
            !isObservationFinished
        else {
            return
        }

        isObservationFinished = true

        let config = userWalletModel.config
        let needBackup = config.hasFeature(.mnemonicBackup) && config.hasFeature(.iCloudBackup)
        let needAccessCode = config.hasFeature(.userWalletAccessCode) && config.userWalletAccessCodeStatus == .none

        guard needBackup || needAccessCode else {
            return
        }

        walletModelsSubscription = userWalletModel
            .totalBalancePublisher
            .map { $0.hasAnyPositiveBalance }
            .filter { $0 }
            .first()
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                manager.onActivation?(userWalletModel)
            }
    }
}

// MARK: - Injections

private struct MobileFinishActivationManagerKey: InjectionKey {
    static var currentValue = MobileFinishActivationManager()
}

extension InjectedValues {
    var mobileFinishActivationManager: MobileFinishActivationManager {
        get { Self[MobileFinishActivationManagerKey.self] }
        set { Self[MobileFinishActivationManagerKey.self] = newValue }
    }
}
