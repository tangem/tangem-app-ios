//
//  MultiWalletMainContentUpdater.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MultiWalletMainContentUpdater {
    static func scheduleUpdate(with userWalletModel: UserWalletModel) async {
        let userTokensManagers = if FeatureProvider.isAvailable(.accounts) {
            userWalletModel.accountModelsManager.cryptoAccountModels.map(\.userTokensManager)
        } else {
            // accounts_fixes_needed_none
            [userWalletModel.userTokensManager]
        }

        await withTaskGroup(of: Void.self) { outerGroup in
            outerGroup.addTask {
                await scheduleUpdate(userTokensManagers: userTokensManagers)
            }

            // [REDACTED_TODO_COMMENT]
            // [REDACTED_INFO]
            if FeatureProvider.isAvailable(.visa), let tangemPayAccount = userWalletModel.tangemPayAccount {
                outerGroup.addTask {
                    await tangemPayAccount.loadCustomerInfo().value
                }
            }

            await outerGroup.waitForAll()
        }
    }

    private static func scheduleUpdate(userTokensManagers: [UserTokensManager]) async {
        return await withCheckedContinuation { checkedContinuation in
            guard userTokensManagers.isNotEmpty else {
                return
            }

            let group = DispatchGroup()
            for userTokensManager in userTokensManagers {
                group.enter()
                userTokensManager.sync {
                    group.leave()
                }
            }
            group.notify(queue: .global(qos: .userInitiated)) {
                checkedContinuation.resume()
            }
        }
    }
}
