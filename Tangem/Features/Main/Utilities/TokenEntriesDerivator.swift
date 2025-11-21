//
//  TokenEntriesDerivator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

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

        if FeatureProvider.isAvailable(.accounts) {
            let group = DispatchGroup()
            var subscription: AnyCancellable?

            // One-time subscription to get the latest list of crypto accounts
            subscription = userWalletModel
                .accountModelsManager
                .cryptoAccountModelsPublisher
                .prefix(1)
                .sink { cryptoAccounts in
                    for account in cryptoAccounts {
                        group.enter()
                        account.userTokensManager.deriveIfNeeded { _ in
                            group.leave()
                        }
                    }
                    withExtendedLifetime(subscription) {}
                }

            group.notify(queue: .main) { [weak self] in
                self?.onFinish()
            }
        } else {
            // accounts_fixes_needed_none
            userWalletModel.userTokensManager.deriveIfNeeded { [weak self] _ in
                DispatchQueue.main.async {
                    self?.onFinish()
                }
            }
        }
    }
}
