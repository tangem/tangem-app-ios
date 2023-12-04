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
    var _selectedUserWalletModel: CurrentValueSubject<UserWalletModel?, Never> { get set }

    /// ViewModels list for wallet selector screen
    var walletSelectorItemViewModels: [WalletSelectorItemViewModel] { get }
}
