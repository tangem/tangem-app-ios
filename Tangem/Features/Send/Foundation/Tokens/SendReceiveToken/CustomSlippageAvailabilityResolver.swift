//
//  CustomSlippageAvailabilityResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CustomSlippageAvailabilityResolver: AccountModelResolving {
    func resolve(accountModel: any StandardCryptoAccountModel) -> Bool {
        true
    }

    func resolve(accountModel: any JointAccountModel) -> Bool {
        true
    }

    func resolve(accountModel: any TangemPayAccountModel) -> Bool {
        false
    }

    func resolve(accountModel: any PolymarketAccountModel) -> Bool {
        false
    }

    func resolve(accountModel: any CollectiblesAccountModel) -> Bool {
        false
    }
}
