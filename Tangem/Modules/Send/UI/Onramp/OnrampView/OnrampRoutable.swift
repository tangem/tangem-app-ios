//
//  OnrampRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampRoutable {
    func openOnrampCountry(country: OnrampCountry, repository: OnrampRepository)
    func openOnrampCountrySelector(repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func openOnrampSettings(repository: OnrampRepository)
    func openOnrampCurrencySelectorView(repository: OnrampRepository, dataRepository: OnrampDataRepository)

    func openOnrampProviders()
}
