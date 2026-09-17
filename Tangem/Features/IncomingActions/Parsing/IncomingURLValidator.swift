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
        guard let scheme = url.scheme, let host = url.host?.lowercased() else {
            return false
        }

        if SupportedURLSchemeCheck.isURLSchemeSupported(for: url) {
            return true
        }

        guard scheme == "https" else {
            return false
        }

        return IncomingActionConstants.supportedExternalLinkHosts.contains(host)
    }
}
