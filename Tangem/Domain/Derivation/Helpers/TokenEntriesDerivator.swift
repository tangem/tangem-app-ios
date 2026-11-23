//
//  TokenEntriesDerivator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class TokenEntriesDerivator {
    private let userWalletModel: UserWalletModel
    private let onStart: () -> Void
    private let onFinish: () -> Void

    init(
        userWalletModel: UserWalletModel,
        onStart: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.onStart = onStart
        self.onFinish = onFinish
        self.userWalletModel = userWalletModel
    }

    func derive() {
        onStart()

        guard let derivationManager = userWalletModel.derivationManager else {
            onFinish()
            return
        }

        runTask { @MainActor [weak self] in
            try? await derivationManager.deriveKeys()
            self?.onFinish()
        }
    }
}
