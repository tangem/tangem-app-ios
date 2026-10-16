//
//  MobileSocialAgreementRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileSocialAgreementRoutable: AnyObject {
    func onSocialAgreementClose()
    func onSocialAgreementAccept(marketingConsent: MobileSocialMarketingConsent)
}
