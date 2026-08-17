//
//  UserTokenListExternalParametersProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol UserTokenListExternalParametersProvider: AnyObject {
    func provideTokenListAddresses() -> [WalletModelId: [String]]?
}
