//
//  UserTokensManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol UserTokensManager {
    func contains(_ tokenItem: TokenItem, derivationPath: DerivationPath?) -> Bool
    func add(_ tokenItem: TokenItem, derivationPath: DerivationPath?, completion: @escaping (Result<Void, TangemSdkError>) -> Void)
    func remove(_ tokenItem: TokenItem, derivationPath: DerivationPath?)
}
