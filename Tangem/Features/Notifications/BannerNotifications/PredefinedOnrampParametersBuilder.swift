//
//  PredefinedOnrampParametersBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemFoundation

class PredefinedOnrampParametersBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.onrampRepository) private var onrampRepository: OnrampRepository

    private let userWalletId: UserWalletId

    private lazy var expressAPIProvider: ExpressAPIProvider = ExpressAPIProviderFactory()
        .makeExpressAPIProvider(userWalletId: userWalletId, refcode: .none)

    private lazy var onrampDataRepository: OnrampDataRepository = TangemExpressFactory().makeOnrampDataRepository(
        expressAPIProvider: expressAPIProvider
    )

    private lazy var onrampManager: any OnrampManager = TangemExpressFactory().makeOnrampManager(
        expressAPIProvider: expressAPIProvider,
        onrampRepository: onrampRepository,
        dataRepository: onrampDataRepository,
        analyticsLogger: MockExpressAnalyticsLogger(),
        providerItemSorter: ProviderItemSorterByPaymentMethodPriority(),
        preferredValues: .init(paymentMethodType: .sepa)
    )

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }

    func prepare(bitcoinWalletModel: any WalletModel) async -> PredefinedOnrampParameters? {
        guard moreThanOneDayAfterFirstWalletUse() else {
            return nil
        }

        guard let (country, currency) = await getPreference() else {
            return nil
        }

        // Check the banner is available in user's country
        guard PredefinedOnrampParametersBuilder.countries.contains(where: { $0.caseInsensitiveEquals(to: country.identity.name) }) else {
            return nil
        }

        // Check the banner is available in user's currency
        guard let fiat = PredefinedOnrampParametersBuilder.fiatPairs[currency.identity.code] else {
            return nil
        }

        // Check the banner is available in express
        guard await sepaProviderIsAvailable(wallet: bitcoinWalletModel, country: country, fiatCurrency: currency) else {
            return nil
        }

        let preferredValues = PreferredValues(paymentMethodType: .sepa)
        return PredefinedOnrampParameters(amount: fiat, preferredValues: preferredValues)
    }

    private func moreThanOneDayAfterFirstWalletUse() -> Bool {
        guard let startAppUsageDate = AppSettings.shared.startAppUsageDate else {
            return false
        }

        guard let oneDayLater = Calendar.current.date(byAdding: .day, value: 1, to: startAppUsageDate) else {
            return false
        }

        return oneDayLater <= Date.now
    }

    private func getPreference() async -> (country: OnrampCountry, currency: OnrampFiatCurrency)? {
        var currency: OnrampFiatCurrency? = onrampRepository.preferenceCurrency
        var country: OnrampCountry? = onrampRepository.preferenceCountry

        let haveToDefine = currency == nil || country == nil
        if haveToDefine {
            let definied = try? await onrampManager.initialSetupCountry()
            if currency == nil {
                currency = definied?.currency
            }

            if country == nil {
                country = definied
            }
        }

        guard let country, let currency else {
            return nil
        }

        return (country: country, currency: currency)
    }

    private func sepaProviderIsAvailable(wallet: any WalletModel, country: OnrampCountry, fiatCurrency: OnrampFiatCurrency) async -> Bool {
        do {
            let request = OnrampPairRequestItem(
                fiatCurrency: fiatCurrency,
                country: country,
                destination: wallet.tokenItem.expressCurrency,
                address: wallet.defaultAddressString
            )

            let providersList = try await onrampManager.setupProviders(request: request)
            let selectableProvider = providersList.select(for: .sepa)?.selectableProvider()
            return selectableProvider != nil
        } catch {
            return false
        }
    }
}

private extension PredefinedOnrampParametersBuilder {
    static let fiatPairs: [String: Decimal] = [
        "EUR": 100,
    ]

    static let countries: [String] = [
        "Albania",
        "Andorra",
        "Austria",
        "Belgium",
        "Bulgaria",
        "Croatia",
        "Cyprus",
        "Czech Republic",
        "Denmark",
        "Estonia",
        "Finland",
        "France",
        "Germany",
        "Greece",
        "Hungary",
        "Iceland",
        "Ireland",
        "Italy",
        "Latvia",
        "Liechtenstein",
        "Lithuania",
        "Luxembourg",
        "Malta",
        "Moldova",
        "Monaco",
        "Montenegro",
        "Netherlands",
        "North Macedonia",
        "Norway",
        "Poland",
        "Portugal",
        "Romania",
        "San Marino",
        "Serbia",
        "Slovakia",
        "Slovenia",
        "Spain",
        "Sweden",
        "Switzerland",
        "United Kingdom",
        "Vatican City",
    ]
}

struct MockExpressAnalyticsLogger: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: TangemExpress.ExpressAvailableProvider) {}

    func logExpressError(_ error: Error, provider: TangemExpress.ExpressProvider?) {}

    func logSwapTransactionAnalyticsEvent(destination: String?) {}

    func logApproveTransactionAnalyticsEvent(policy: BlockchainSdk.ApprovePolicy, destination: String?) {}

    func logApproveTransactionSentAnalyticsEvent(policy: BlockchainSdk.ApprovePolicy, signerType: String) {}

    func logAppError(_ error: any Error, provider: TangemExpress.ExpressProvider) {}

    func logExpressAPIError(_ error: TangemExpress.ExpressAPIError, provider: TangemExpress.ExpressProvider, paymentMethod: TangemExpress.OnrampPaymentMethod) {}
}
