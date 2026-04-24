//
//  SolanaDummyAccountStorage.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

class SolanaDummyAccountStorage: SolanaAccountStorage {
    func save(_ account: Account) -> Result<Void, Error> {
        return .failure(SolanaBSDKError.notImplemented)
    }

    var account: Result<Account, Error> {
        return .failure(SolanaBSDKError.notImplemented)
    }

    func clear() -> Result<Void, Error> {
        return .failure(SolanaBSDKError.notImplemented)
    }
}
