//
//  TransferTypeOption.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum TransferTypeOption: CaseIterable, Identifiable {
    case ownAccount
    case thirdParty

    var id: Self { self }

    var title: String {
        switch self {
        case .ownAccount:
            Localization.tangempayWithdrawBankTransferTypeOwn
        case .thirdParty:
            Localization.tangempayWithdrawBankTransferTypeThirdParty
        }
    }

    var isThirdParty: Bool {
        switch self {
        case .ownAccount: false
        case .thirdParty: true
        }
    }

    init(isThirdParty: Bool) {
        self = isThirdParty ? .thirdParty : .ownAccount
    }
}
