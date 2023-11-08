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
    var userWalletModels: [UserWalletModel] { get set }
    var selectedUserWalletId: UserWalletId { get set }

    var selectedUserWalletModelPublisher: AnyPublisher<UserWalletModel, Never> { get set }
}
