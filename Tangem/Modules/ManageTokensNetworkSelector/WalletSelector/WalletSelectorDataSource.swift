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
    var selectedUserWalletModelPublisher: CurrentValueSubject<UserWalletModel?, Never> { get set }
}
