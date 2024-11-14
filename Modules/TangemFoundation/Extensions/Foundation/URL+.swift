//
//  URL+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension URL {
    var topLevelDomain: String? {
        let separator = "."
        let rawHost: String?

        if #available(iOS 16.0, *) {
            rawHost = host()
        } else {
            rawHost = host
        }

        guard let rawHost else {
            return nil
        }

        let components = rawHost.components(separatedBy: separator)

        guard components.count > 1 else {
            return rawHost
        }

        return components.suffix(2).joined(separator: separator)
    }
}
