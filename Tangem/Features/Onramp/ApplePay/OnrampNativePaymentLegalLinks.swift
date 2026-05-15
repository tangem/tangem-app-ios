//
//  OnrampNativePaymentLegalLinks.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum OnrampNativePaymentLegalLinks {
    // Temporary: ExpressProvider DTO does not carry a Cookie Policy URL today.
    // Replace this lookup when backend extends the DTO.
    static func cookiePolicyURL(providerId: String) -> URL? {
        switch providerId.lowercased() {
        case "mercuryo": URL(string: "https://mercuryo.io/legal/cookie-policy/")
        default: nil
        }
    }
}
