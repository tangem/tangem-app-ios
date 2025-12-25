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

            // [REDACTED_TODO_COMMENT]
            // [REDACTED_INFO]
            if FeatureProvider.isAvailable(.visa), let paeraCustomer = userWalletModel.paeraCustomer {
                outerGroup.addTask {
                    // [REDACTED_TODO_COMMENT]
//                    await paeraCustomer.updateState().value
                }
            }

            await outerGroup.waitForAll()
        }
    }

    private static func scheduleUpdateInternal(with userWalletModel: UserWalletModel) async {
        return await withCheckedContinuation { checkedContinuation in

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
                            account.userTokensManager.sync {
                                group.leave()
                            }
                        }
                        withExtendedLifetime(subscription) {}
                    }

                group.notify(queue: .global(qos: .userInitiated)) {
                    checkedContinuation.resume()
                }
            } else {
                // accounts_fixes_needed_none
                userWalletModel.userTokensManager.sync {
                    checkedContinuation.resume()
                }
            }
        }
    }
}
