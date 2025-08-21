//
//  PredefinedOnrampParametersBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct PredefinedOnrampParametersBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    private let userWalletId: UserWalletId
    private let expressAPIProvider: any ExpressAPIProvider
    private let onrampRepository: any OnrampRepository

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId

        expressAPIProvider = ExpressAPIProviderFactory()
            .makeExpressAPIProvider(userWalletId: userWalletId, refcode: .none)

        onrampRepository = TangemExpressFactory().makeOnrampRepository(storage: CommonOnrampStorage())
    }

    func prepare() async -> (bitcoinWalletModel: any WalletModel, parameters: PredefinedOnrampParameters)? {
        guard moreThanOneWeekAfterFirstWalletUse() else {
            return nil
        }

        guard let bitcoinWalletModel = getBitcoinWalletModel() else {
            return nil
        }

        guard let parameters = await getParameters() else {
            return nil
        }

        return (bitcoinWalletModel: bitcoinWalletModel, parameters: parameters)
    }

    private func moreThanOneWeekAfterFirstWalletUse() -> Bool {
        guard let startWalletUsageDate = AppSettings.shared.startWalletUsageDate else {
            return false
        }

        guard let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: startWalletUsageDate) else {
            return false
        }

        return oneWeekLater < Date.now
    }

    private func getBitcoinWalletModel() -> (any WalletModel)? {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return nil
        }

        let walletModels = userWalletModel.walletModelsManager.walletModels
        let bitcoinWalletModel = walletModels.first(where: {
            $0.isMainToken && $0.tokenItem.blockchain == .bitcoin(testnet: false)
        })

        return bitcoinWalletModel
    }

    private func getParameters() async -> PredefinedOnrampParameters? {
        var currency: OnrampFiatCurrency? = onrampRepository.preferenceCurrency

        if currency == nil {
            currency = try? await expressAPIProvider.onrampCountryByIP().currency
        }

        guard let currency,
              let fiat = PredefinedOnrampParametersBuilder.fiatPairs[currency.identity.code] else {
            return nil
        }

        let preferredValues = PreferredValues(paymentMethodType: .sepa)
        return PredefinedOnrampParameters(amount: fiat, preferredValues: preferredValues)
    }
}

extension PredefinedOnrampParametersBuilder {
    static let fiatPairs: [String: Decimal] = [
        "ALL": 10000,
        "EUR": 100,
        "BGN": 200,
        "CZK": 2500,
        "DKK": 800,
        "HUF": 40000,
        "ISK": 14000,
        "CHF": 100,
        "MDL": 2000,
        "MKD": 6000,
        "NOK": 1000,
        "PLN": 400,
        "RSD": 12000,
        "SEK": 1000,
        "GBP": 100,
    ]
}
