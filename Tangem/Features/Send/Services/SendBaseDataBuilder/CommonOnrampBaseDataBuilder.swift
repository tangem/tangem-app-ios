//
//  CommonOnrampBaseDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine

struct CommonOnrampBaseDataBuilder {
    private let config: UserWalletConfig
    private let onrampRepository: OnrampRepository
    private let onrampDataRepository: OnrampDataRepository
    private let providersBuilder: OnrampProvidersBuilder
    private let paymentMethodsBuilder: OnrampPaymentMethodsBuilder
    private let onrampRedirectingBuilder: OnrampRedirectingBuilder

    init(
        config: UserWalletConfig,
        onrampRepository: OnrampRepository,
        onrampDataRepository: OnrampDataRepository,
        providersBuilder: OnrampProvidersBuilder,
        paymentMethodsBuilder: OnrampPaymentMethodsBuilder,
        onrampRedirectingBuilder: OnrampRedirectingBuilder
    ) {
        self.config = config
        self.onrampRepository = onrampRepository
        self.onrampDataRepository = onrampDataRepository
        self.providersBuilder = providersBuilder
        self.paymentMethodsBuilder = paymentMethodsBuilder
        self.onrampRedirectingBuilder = onrampRedirectingBuilder
    }
}

// MARK: - OnrampBaseDataBuilder

extension CommonOnrampBaseDataBuilder: OnrampBaseDataBuilder {
    func makeDataForOnrampCountryBottomSheet() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository) {
        (repository: onrampRepository, dataRepository: onrampDataRepository)
    }

    func makeDataForOnrampCountrySelectorView() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository) {
        (repository: onrampRepository, dataRepository: onrampDataRepository)
    }

    func makeDataForOnrampProvidersPaymentMethodsView() -> (providersBuilder: OnrampProvidersBuilder, paymentMethodsBuilder: OnrampPaymentMethodsBuilder) {
        (providersBuilder: providersBuilder, paymentMethodsBuilder: paymentMethodsBuilder)
    }

    func makeDataForOnrampRedirecting() -> OnrampRedirectingBuilder {
        onrampRedirectingBuilder
    }

    func demoAlertMessage() -> String? {
        config.getDisabledLocalizedReason(for: .exchange)
    }
}
