//
//  OnrampModelRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

/// Uses for connect `OnrampModel` -> `CommonOnrampStepsManager`
protocol OnrampModelRoutable: AnyObject {
    func openOnrampCountryBottomSheet(country: OnrampCountry)
    func openOnrampCountrySelectorView()
    func openOnrampRedirecting()
    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void)
    func openFinishStep()
}
