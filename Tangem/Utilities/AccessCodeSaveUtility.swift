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
    func trySave(accessCode: String, cardIds: [String]) {
        guard AppSettings.shared.saveAccessCodes else {
            return
        }

        let accessCodeData: Data = accessCode.sha256()
        let accessCodeRepository = AccessCodeRepository()
        try? accessCodeRepository.save(accessCodeData, for: cardIds)
    }
}
