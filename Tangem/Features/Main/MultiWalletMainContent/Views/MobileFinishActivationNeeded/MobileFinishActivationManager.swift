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

    func observe(userWalletId: UserWalletId, onActivation: @escaping Activation) {
        self.userWalletId = userWalletId
        self.onActivation = onActivation
        isObservationFinished = false
    }

    func activateIfNeeded(userWalletModel: UserWalletModel) {
        guard
            let userWalletId, let onActivation,
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
            let totalBalances = walletModels.compactMap(\.availableBalanceProvider.balanceType.value)
            let hasPositiveBalance = totalBalances.contains(where: { $0 > 0 })

            if hasPositiveBalance {
                onActivation(userWalletModel)
            }
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
