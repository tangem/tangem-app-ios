//
//  CollectiblesHotDelegateKeyStore.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
public import TangemFoundation

public protocol CollectiblesHotDelegateKeyStore: AnyObject {
    func storePrivateKey(_ seed: Data, userWalletId: UserWalletId) throws
    func privateKey(userWalletId: UserWalletId) throws -> Data?
    func deletePrivateKey(userWalletId: UserWalletId) throws
}
