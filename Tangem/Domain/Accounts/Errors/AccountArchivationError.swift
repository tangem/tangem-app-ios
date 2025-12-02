//
//  AccountArchivationError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum AccountArchivationError: Error {
    case participatesInReferralProgram
    case unknownError(Error)
}
