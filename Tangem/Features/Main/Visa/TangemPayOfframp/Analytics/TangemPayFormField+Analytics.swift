//
//  TangemPayFormField+Analytics.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension TangemPayFormField.ID {
    var analyticsName: String {
        switch self {
        case .email: "Email"
        case .accountNumber: "Account Number"
        case .routingNumber: "Routing Number"
        case .firstName: "First Name"
        case .lastName: "Last Name"
        case .businessName: "Business Name"
        case .countryCode: "Country"
        case .region: "Region"
        case .city: "City"
        case .line1: "Address Line 1"
        case .line2: "Address Line 2"
        case .postalCode: "Postal Code"
        case .bankName: "Bank Name"
        case .bankRegion: "Bank Region"
        case .bankCity: "Bank City"
        case .bankLine1: "Bank Address Line 1"
        case .bankPostalCode: "Bank Postal Code"
        }
    }
}
