//
//  WarningEvent+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension WarningEvent {
    var warning: AppWarning {
        switch self {
        case .numberOfSignedHashesIncorrect:
            return WarningsList.numberOfSignedHashesIncorrect
        case .rateApp:
            return WarningsList.rateApp
        case .failedToValidateCard:
            return WarningsList.failedToVerifyCard
        case .multiWalletSignedHashes:
            return WarningsList.multiWalletSignedHashes
        case .testnetCard:
            return WarningsList.testnetCard
        case .fundsRestoration:
            return WarningsList.fundsRestoration
        }
    }
}
