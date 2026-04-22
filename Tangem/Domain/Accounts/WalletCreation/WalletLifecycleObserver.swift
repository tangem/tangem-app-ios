//
//  WalletLifecycleObserver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol WalletLifecycleObserver {
    func walletDidCreate(with userWalletId: UserWalletId)
}
