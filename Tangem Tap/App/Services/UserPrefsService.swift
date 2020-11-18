//
//  UserPrefsService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class UserPrefsService {
    @Storage("tangem_tap_terms_of_service_accepted", defaultValue: false)
    var isTermsOfServiceAccepted: Bool
}
