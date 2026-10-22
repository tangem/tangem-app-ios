//
//  MobileSocialWalletFailure.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum MobileSocialWalletFailure {
    case somethingWentWrong

    var message: String {
        switch self {
        case .somethingWentWrong:
            Localization.socialLoginErrorGeneric
        }
    }
}
