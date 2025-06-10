//
//  UpdatableAllowanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol UpdatableAllowanceProvider: AllowanceProvider, ExpressAllowanceProvider {
    func setup(wallet: any WalletModel)
}
