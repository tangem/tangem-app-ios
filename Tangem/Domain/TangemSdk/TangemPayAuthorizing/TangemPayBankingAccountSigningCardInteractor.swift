//
//  TangemPayBankingAccountSigningCardInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemPay

final class TangemPayBankingAccountSigningCardInteractor: TangemPayBankingAccountAddressSigning {
    private let tangemSdk: TangemSdk
    private let filter: SessionFilter

    init(with cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        tangemSdk = config.makeTangemSdk()
        filter = config.cardSessionFilter
    }

    func signDepositAddress() async throws(TangemPayBankingAccountSigningError) -> TangemPayBankingAccountSigningResponse {
        let task = TangemPayBankingAccountDepositAddressSigningTask()

        let response: TangemPayBankingAccountDepositAddressSigningTask.Response = await withCheckedContinuation { continuation in
            tangemSdk.startSession(with: task, filter: filter) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(returning: .init(result: .failure(error), derivationResult: [:]))
                }

                withExtendedLifetime(task) {}
            }
        }

        switch response.result {
        case .success(let signingResponse):
            return signingResponse
        case .failure(let error):
            throw TangemPayBankingAccountSigningError(underlyingError: error, derivationResult: response.derivationResult)
        }
    }
}
