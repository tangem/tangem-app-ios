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
    /// Available UserWalletModel list with filter for current external flow
    var userWalletModels: [UserWalletModel] { get set }

    /// Published value selected UserWalletModel
    var selectedUserWalletModelPublisher: CurrentValueSubject<UserWalletModel?, Never> { get set }
}
