//
//  ResetToFactoryViewModelInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension ResetToFactoryViewModel {
    struct Input {
        let cardInteractor: FactorySettingsResetting
        let hasBackupCards: Bool
        let userWalletId: UserWalletId
    }
}
