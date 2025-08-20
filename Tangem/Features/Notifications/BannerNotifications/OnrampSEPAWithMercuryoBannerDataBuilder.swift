//
//  OnrampSEPAWithMercuryoBannerDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct OnrampSEPAWithMercuryoBannerDataBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    private let fiatValue: [String: Decimal] = ["EUR": 100]

    func prepare(userWalletId: UserWalletId) -> (bitcoinWalletModel: any WalletModel, parameters: PredefinedOnrampParameters)? {
        guard let bitcoinWalletModel = getBitcoinWalletModel(userWalletId: userWalletId) else {
            return nil
        }

        guard let parameters = getParameters() else {
            return nil
        }

        return (bitcoinWalletModel: bitcoinWalletModel, parameters: parameters)
    }

    private func getParameters() -> PredefinedOnrampParameters? {
        let repository = TangemExpressFactory().makeOnrampRepository(storage: CommonOnrampStorage())

        guard let currency = repository.preferenceCurrency,
              let fiat = fiatValue[currency.identity.code] else {
            return nil
        }

        let preferredProvider = PreferredProvider(providerId: "mercuryo", paymentMethodType: .sepa)
        return PredefinedOnrampParameters(amount: fiat, preferredProvider: preferredProvider)
    }

    private func getBitcoinWalletModel(userWalletId: UserWalletId) -> (any WalletModel)? {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return nil
        }

        let walletModels = userWalletModel.walletModelsManager.walletModels
        let bitcoinWalletModel = walletModels.first(where: {
            $0.isMainToken && $0.tokenItem.blockchain == .bitcoin(testnet: false)
        })

        return bitcoinWalletModel
    }
}
