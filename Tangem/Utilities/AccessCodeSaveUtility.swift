//
//  AccessCodeSaveUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct AccessCodeSaveUtility {
    func trySave(accessCode: String, cardIds: Set<String>) {
        guard AppSettings.shared.saveAccessCodes else {
            return
        }

        let accessCodeData: Data = accessCode.getSHA256()
        let accessCodeRepository = AccessCodeRepository()
        try? accessCodeRepository.save(accessCodeData, for: Array(cardIds))
    }
}
