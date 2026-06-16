//
//  OnrampNativePaymentLegalLinks.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

enum OnrampNativePaymentLegalLinks {
    static func legalNotice(for provider: OnrampProvider) -> OnrampOfferViewModel.LegalNotice {
        OnrampOfferViewModel.LegalNotice(
            providerName: provider.provider.name,
            termsOfUse: provider.provider.termsOfUse,
            privacyPolicy: provider.provider.privacyPolicy
        )
    }
}
