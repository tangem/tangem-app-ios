//
//  MobileFinishActivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
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

        let cachedBalance: Decimal = switch userWalletModel.totalBalance {
        case .loaded(let balance): balance
        case .loading(let cachedBalance): cachedBalance ?? 0
        case .failed(let cachedBalance, _): cachedBalance ?? 0
        case .empty: 0
        }

        guard cachedBalance > 0 else {
            return
        }

        let config = userWalletModel.config
        let needBackup = config.hasFeature(.mnemonicBackup) && config.hasFeature(.iCloudBackup)
        let needAccessCode = config.hasFeature(.userWalletAccessCode) && config.userWalletAccessCodeStatus == .none

        guard needBackup || needAccessCode else {
            return
        }

        onActivation(userWalletModel)
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
