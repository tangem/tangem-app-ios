//
//  CommonTokenSelectorTangemPayAccountModelItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class CommonTokenSelectorTangemPayAccountModelItemsProvider {
    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccountModel: any TangemPayAccountModel

    init(userWalletInfo: UserWalletInfo, tangemPayAccountModel: any TangemPayAccountModel) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccountModel = tangemPayAccountModel
    }
}

extension CommonTokenSelectorTangemPayAccountModelItemsProvider: TokenSelectorAccountModelItemsProvider {
    var itemsPublisher: AnyPublisher<[TokenSelectorItem], Never> {
        tangemPayAccountModel
            .statePublisher
            .withWeakCaptureOf(self)
            .map { provider, state in
                provider.tokenSelectorItems(state: state)
            }
            .eraseToAnyPublisher()
    }
}

private extension CommonTokenSelectorTangemPayAccountModelItemsProvider {
    func tokenSelectorItems(state: TangemPayLocalState?) -> [TokenSelectorItem] {
        guard let tangemPayAccount = state?.tangemPayAccount,
              let depositAddress = tangemPayAccount.depositAddress
        else {
            return []
        }

        return [
            TokenSelectorItem(
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
