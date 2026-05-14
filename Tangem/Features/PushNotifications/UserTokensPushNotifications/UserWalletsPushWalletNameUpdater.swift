//
//  UserWalletsPushWalletNameUpdater.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol UserWalletsPushWalletNameUpdating {
    func updateWalletName(name: String, userWalletId: String) async
}

final class UserWalletsPushWalletNameUpdater: UserWalletsPushWalletNameUpdating {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    func updateWalletName(name: String, userWalletId: String) async {
        do {
            let requestModel = UserWalletDTO.Update.Request(name: name)
            try await tangemApiService.updateUserWallet(by: userWalletId, requestModel: requestModel)
        } catch {
            AppLogger.error(error: error)
        }
    }
}
