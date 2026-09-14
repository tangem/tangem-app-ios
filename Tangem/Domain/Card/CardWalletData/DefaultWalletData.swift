//
//  DefaultWalletData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemVisa
import TangemMacro

@CaseFlagable
enum DefaultWalletData: Codable {
    case file(WalletData)
    case legacy(WalletData)
    case twin(WalletData, TwinData)
    case visa(VisaCardActivationLocalState)
    case none

    var twinData: TwinData? {
        if case .twin(_, let data) = self {
            return data
        }

        return nil
    }
}
