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
    private let primaryCardFirmwareVersion: FirmwareVersion?

    init(primaryCardFirmwareVersion: FirmwareVersion?) {
        self.primaryCardFirmwareVersion = primaryCardFirmwareVersion
    }

    func trySave(accessCode: String, cardIds: Set<String>) {
        guard AppSettings.shared.saveAccessCodes else {
            return
        }

        let accessCodeData: Data = accessCode.getSHA256()
        let accessCodeRepository = AccessCodeRepository()

        guard let primaryCardFirmwareVersion else {
            AppLogger.error("Failed to save access code. Primary card firmware version is nil", error: Error.primaryCardFirmwareVersionUnavailable)
            return
        }

        try? accessCodeRepository.save(
            accessCodeData,
            for: Array(cardIds),
            firmwareVersion: primaryCardFirmwareVersion
        )
    }
}

private extension AccessCodeSaveUtility {
    enum Error: Swift.Error {
        case primaryCardFirmwareVersionUnavailable
    }
}
