//
//  EarnAddTokenRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol EarnAddTokenRoutable: AnyObject, AddTokenFlowRoutable {
    func presentTokenDetails(by walletModel: any WalletModel, with userWalletModel: UserWalletModel)
}
