//
//  OnrampRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampRoutable {
    func openOnrampCountryDetection(country: OnrampCountry, repository: any OnrampRepository, dataRepository: any OnrampDataRepository)
    func openOnrampSettings(repository: any OnrampRepository, dataRepository: any OnrampDataRepository)
    func openOnrampCurrencySelector(repository: any OnrampRepository, dataRepository: any OnrampDataRepository)
    func openOnrampProviders(providersBuilder: OnrampProvidersBuilder, paymentMethodsBuilder: OnrampPaymentMethodsBuilder)
    func openOnrampRedirecting(onrampRedirectingBuilder: OnrampRedirectingBuilder)
    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void)
}
