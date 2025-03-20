//
//  MainHeaderUserWalletStateInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainHeaderUserWalletStateInfoProvider: AnyObject {
    var isUserWalletLocked: Bool { get }
    var isTokensListEmpty: Bool { get }
}
