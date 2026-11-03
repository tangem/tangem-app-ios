//
//  PromoPageURLValidator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PromoPageURLValidator {
    func validatedURL(from page: String) -> URL? {
        guard let url = URL(string: page), isAllowed(url) else {
            return nil
        }

        return url
    }

    func isAllowed(_ url: URL) -> Bool {
        guard url.isHTTPS,
              url.user == nil,
              url.password == nil,
              url.port == nil,
              let host = url.host?.lowercased() else {
            return false
        }

        return Constants.allowedHosts.contains(host)
    }
}

// MARK: - Constants

private extension PromoPageURLValidator {
    enum Constants {
        static let allowedHosts: Set<String> = [
            "tangem.com",
            "www.tangem.com",
            "buy.tangem.com",
            "app.tangem.com",
            "tangem.surveysparrow.com",
            "feedback.tangem.com",
            "promo.tangem.com",
        ]
    }
}
