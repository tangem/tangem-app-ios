//
//  MultiWalletMainContentUpdater.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum MultiWalletMainContentUpdater {
    static func scheduleUpdate(with userWalletModel: UserWalletModel) async {
        await withTaskGroup { outerGroup in
            outerGroup.addTask {
                await scheduleUpdateInternal(with: userWalletModel)
            }

            outerGroup.addTask {
                await AccountModelsAggregator(.tangemPay).model(from: userWalletModel.accountModelsManager)?.refreshState()
            }

            outerGroup.addTask {
                await AccountModelsAggregator(.polymarket).model(from: userWalletModel.accountModelsManager)?.refreshState()
            }

            outerGroup.addTask {
                await AccountModelsAggregator(.collectibles).model(from: userWalletModel.accountModelsManager)?.refreshState()
            }

            await outerGroup.waitForAll()
        }
    }

    private static func scheduleUpdateInternal(with userWalletModel: UserWalletModel) async {
        return await withCheckedContinuation { checkedContinuation in
            let group = DispatchGroup()
            var subscription: AnyCancellable?

            // One-time subscription to get the latest list of crypto accounts
            subscription = AccountModelsAggregator(.crypto, .joint)
                .modelsPublisher(from: userWalletModel.accountModelsManager)
                .prefix(1)
                .sink { cryptoAccounts in
                    for account in cryptoAccounts {
                        group.enter()
                        account.userTokensManager.sync {
                            group.leave()
                        }
                    }
                    withExtendedLifetime(subscription) {}
                }

            group.notify(queue: .global(qos: .userInitiated)) {
                checkedContinuation.resume()
            }
        }
    }
}
