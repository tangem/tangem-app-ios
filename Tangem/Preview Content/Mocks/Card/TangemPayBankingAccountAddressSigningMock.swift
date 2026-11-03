//
//  TangemPayBankingAccountAddressSigningMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

class TangemPayBankingAccountAddressSigningMock: TangemPayBankingAccountAddressSigning {
    func signDepositAddress() async throws(TangemPayBankingAccountSigningError) -> TangemPayBankingAccountSigningResponse {
        TangemPayBankingAccountSigningResponse(depositAddress: "", signature: "", derivationResult: [:])
    }
}
