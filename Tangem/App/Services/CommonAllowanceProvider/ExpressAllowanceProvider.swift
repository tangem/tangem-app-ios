//
//  ExpressAllowanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol ExpressAllowanceProvider: AllowanceProvider {
    func setup(wallet: WalletModel)
    func didSendApproveTransaction(for spender: String)
}
