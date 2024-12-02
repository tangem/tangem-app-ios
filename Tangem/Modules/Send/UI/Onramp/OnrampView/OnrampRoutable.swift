//
//  OnrampRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampRoutable {
    func openOnrampCountryDetection(country: OnrampCountry, repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func openOnrampCountrySelector(repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func openOnrampSettings(repository: OnrampRepository)
    func openOnrampCurrencySelector(repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func openOnrampProviders(providersBuilder: OnrampProvidersBuilder, paymentMethodsBuilder: OnrampPaymentMethodsBuilder)
    func openOnrampRedirecting(onrampRedirectingBuilder: OnrampRedirectingBuilder)
    func openOnrampWebView(url: URL, success: @escaping () -> Void)
}
