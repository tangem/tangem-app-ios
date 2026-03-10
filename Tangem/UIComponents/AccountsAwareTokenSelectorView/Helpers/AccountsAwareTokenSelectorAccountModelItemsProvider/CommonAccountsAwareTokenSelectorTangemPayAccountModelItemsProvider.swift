//
//  CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider {
    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccountModel: any TangemPayAccountModel

    init(userWalletInfo: UserWalletInfo, tangemPayAccountModel: any TangemPayAccountModel) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccountModel = tangemPayAccountModel
    }
}

extension CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider: AccountsAwareTokenSelectorAccountModelItemsProvider {
    var items: [AccountsAwareTokenSelectorItem] {
        tokenSelectorItems(state: tangemPayAccountModel.state)
    }

    var itemsPublisher: AnyPublisher<[AccountsAwareTokenSelectorItem], Never> {
        tangemPayAccountModel
            .statePublisher
            .withWeakCaptureOf(self)
            .map { provider, state in
                provider.tokenSelectorItems(state: state)
            }
            .eraseToAnyPublisher()
    }
}

private extension CommonAccountsAwareTokenSelectorTangemPayAccountModelItemsProvider {
    func tokenSelectorItems(state: TangemPayLocalState?) -> [AccountsAwareTokenSelectorItem] {
        guard let tangemPayAccount = state?.tangemPayAccount,
              let depositAddress = tangemPayAccount.depositAddress
        else {
            return []
        }

        return [
            AccountsAwareTokenSelectorItem(
                userWalletInfo: userWalletInfo,
                kind: .tangemPay(
                    tangemPayAccount,
                    depositAddress,
                    tangemPayAccountModel
                )
            ),
        ]
    }
}
