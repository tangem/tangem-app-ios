//
//  ResetToFactoryViewModelInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension ResetToFactoryViewModel {
    struct Input {
        let cardInteractor: FactorySettingsResetting
        let backupCardsCount: Int
        let userWalletId: UserWalletId
    }
}
