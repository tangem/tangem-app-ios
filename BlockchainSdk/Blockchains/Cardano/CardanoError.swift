//
//  CardanoError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum CardanoError: String, Error, LocalizedError {
    case noUnspents
    case lowAda

    var errorDescription: String? {
        Localization.genericErrorCode(errorCodeDescription)
    }

    private var errorCodeDescription: String {
        return "cardano_error \(errorCode)"
    }

    private var errorCode: Int {
        switch self {
        case .noUnspents:
            return 1
        case .lowAda:
            return 2
        }
    }
}
