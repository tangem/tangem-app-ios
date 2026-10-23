//
//  MobileSocialWalletRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileSocialWalletRoutable: AnyObject {
    func socialWalletOpenMain(userWalletModel: UserWalletModel)
    func socialWalletFailed(failure: MobileSocialWalletFailure)
    func socialWalletClose()
}
