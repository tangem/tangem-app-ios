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
}

extension CommonIncomingURLValidator: IncomingURLValidator {
    public func validate(_ url: URL) -> Bool {
        guard let scheme = url.scheme, let host = url.host else {
            return false
        }

        if SupportedURLSchemeCheck.isURLSchemeSupported(for: url) {
            return true
        }

        // The check for correct host i.e. deeplink destination happens in deeplink parsers
        if scheme == IncomingActionConstants.universalLinkScheme {
            return true
        }

        if TangemPayOnboardingLinkParser.matches(url) {
            return true
        }

        if scheme == "https" {
            return IncomingActionConstants.supportedExternalLinkHosts.contains(host.lowercased())
        }

        return false
    }
}
