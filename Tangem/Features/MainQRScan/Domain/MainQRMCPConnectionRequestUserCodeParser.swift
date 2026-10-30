//
//  MainQRMCPConnectionRequestUserCodeParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URLComponents

// [REDACTED_TODO_COMMENT]
enum MainQRMCPConnectionRequestUserCodeParser {
    static func parse(_ input: String) -> String? {
        guard
            let components = URLComponents(string: input),
            components.scheme == "tangem",
            components.host == "mcp.authorization"
        else {
            return nil
        }

        return components.queryItems?.first { $0.name == "user_code" }?.value
    }
}
