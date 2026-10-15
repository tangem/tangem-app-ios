//
//  CollectiblesPackPurchaseInteractorStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

@MainActor
enum CollectiblesPackPurchaseInteractorStore {
    private static var interactors: [UserWalletId: CommonCollectiblesPackPurchaseInteractor] = [:]

    static func interactor(
        for userWalletId: UserWalletId,
        make: () -> CommonCollectiblesPackPurchaseInteractor
    ) -> CommonCollectiblesPackPurchaseInteractor {
        if let interactor = interactors[userWalletId] {
            return interactor
        }

        let interactor = make()
        interactors[userWalletId] = interactor

        return interactor
    }
}
