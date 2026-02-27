//
//  OnrampRouterDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampRouterDataBuilder {
    func makeDataForOnrampCountryBottomSheet() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func makeDataForOnrampCountrySelectorView() -> (repository: OnrampRepository, dataRepository: OnrampDataRepository)
    func makeDataForOnrampRedirecting() -> OnrampRedirectingBuilder
    func demoAlertMessage() -> String?
}
