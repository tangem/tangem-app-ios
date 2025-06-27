//
//  IncomingURLValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol IncomingURLValidator {
    func validate(_ url: URL) -> Bool
}

public struct CommonIncomingURLValidator {
    public init() {}

    private func validateUniversalLilk(_ url: URL) -> Bool {
        return false
    }
}

extension CommonIncomingURLValidator: IncomingURLValidator {
    public func validate(_ url: URL) -> Bool {
        guard
            let scheme = url.scheme,
            let host = url.host
        else {
            return false
        }

        if SupportedURLSchemeCheck.isURLSchemeSupported(for: url) {
            return true
        }

        // The check for corretc host i.e. deeplink desitantion happens in deeplink parsers
        if scheme == IncomingActionConstants.universalLinkScheme {
            return true
        }

        if scheme == "https" {
            return host == IncomingActionConstants.tangemHost || host == IncomingActionConstants.appTangemHost
        }

        return false
    }
}
