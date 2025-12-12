//
//  UserWalletInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletInfoProvider: AnyObject {
    var userWalletInfo: UserWalletInfo { get }
}
