//
//  CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider {
    let userWalletInfo: UserWalletInfo
    let tangemPayAccountModel: any TangemPayAccountModel
}

extension CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider: AccountsAwareTokenSelectorAccountModelItemsProvider {
    var items: [AccountsAwareTokenSelectorItem] {
        guard let tangemPayAccount = tangemPayAccountModel.state?.tangemPayAccount,
              let depositAddress = tangemPayAccount.depositAddress
        else {
            return []
        }

        return [
            .init(
                userWalletInfo: userWalletInfo,
                kind: .tangemPay(
                    tangemPayAccount,
                    depositAddress,
                    tangemPayAccountModel
                )
            ),
        ]
    }

    var itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItem], Never> {
        tangemPayAccountModel
            .statePublisher
            .map { [userWalletInfo, tangemPayAccountModel] state in
                guard let tangemPayAccount = state.tangemPayAccount,
                      let depositAddress = tangemPayAccount.depositAddress
                else {
                    return []
                }

                return [
                    .init(
                        userWalletInfo: userWalletInfo,
                        kind: .tangemPay(
                            tangemPayAccount,
                            depositAddress,
                            tangemPayAccountModel
                        )
                    ),
                ]
            }
            .eraseToAnyPublisher()
    }
}
