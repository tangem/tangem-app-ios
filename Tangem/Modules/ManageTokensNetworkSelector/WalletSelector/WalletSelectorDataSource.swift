//
//  WalletSelectorDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol WalletSelectorDataSource: AnyObject {
    /// Published value selected UserWalletModel
    var selectedUserWalletModelPublisher: AnyPublisher<UserWalletModel?, Never> { get }

    /// ViewModels list for wallet selector screen
    var itemViewModels: [WalletSelectorItemViewModel] { get }
}
