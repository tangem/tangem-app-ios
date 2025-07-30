//
//  CommonHotAccessCodeManagerDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol CommonHotAccessCodeManagerDelegate: AnyObject {
    func handleAccessCodeSuccessful(userWalletModel: UserWalletModel)
    func handleAccessCodeDelete(userWalletModel: UserWalletModel)
}
