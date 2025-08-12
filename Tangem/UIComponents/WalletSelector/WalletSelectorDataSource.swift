//
//  WalletSelectorDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol WalletSelectorDataSource: AnyObject {
    /// Published value selected UserWalletModel
    var selectedUserWalletIdPublisher: AnyPublisher<UserWalletId?, Never> { get }

    /// ViewModels list for wallet selector screen
    var itemViewModels: [WalletSelectorItemViewModel] { get }
}
