//
//  IconURLBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct IconURLBuilder {
    private let baseURL: URL

    init(baseURL: URL = AppEnvironment.current.iconBaseUrl) {
        self.baseURL = baseURL
    }

    func tokenIconURL(id: String, size: TokenURLIconSize = .large) -> URL {
        baseURL
            .appendingPathComponent("coins")
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent("\(id).png")
    }

    func tokenIconURL(optionalId: String?, size: TokenURLIconSize = .large) -> URL? {
        guard let optionalId else {
            return nil
        }

        return tokenIconURL(id: optionalId, size: size)
    }

    func fiatIconURL(currencyCode: String) -> URL {
        baseURL
            .appendingPathComponent("currencies")
            .appendingPathComponent("medium")
            .appendingPathComponent("\(currencyCode.lowercased()).png")
    }

    func exchangesIconURL(exchangeId: String, size: TokenURLIconSize = .large) -> URL {
        baseURL
            .appendingPathComponent("exchanges")
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent("\(exchangeId.lowercased()).png")
    }

    func securityScoreProviderIconURL(providerId: String, size: TokenURLIconSize = .large) -> URL {
        baseURL
            .appendingPathComponent("security_provider")
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent(providerId.lowercased())
            .appendingPathExtension(for: .png)
    }
}
