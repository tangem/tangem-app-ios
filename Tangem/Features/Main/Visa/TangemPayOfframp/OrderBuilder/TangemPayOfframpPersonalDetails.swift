//
//  TangemPayOfframpPersonalDetails.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

struct TangemPayOfframpPersonalDetails: Equatable {
    let name: Name
    let accountNumber: String
    let routingNumber: String
    let line1: String
    let line2: String?
    let city: String
    let country: TangemPayGeoCountry
    let region: TangemPayGeoRegion?
    let regionText: String
    let postalCode: String
}

// MARK: - Name

extension TangemPayOfframpPersonalDetails {
    enum Name: Equatable {
        case individual(firstName: String, lastName: String)
        case business(name: String)
    }
}
