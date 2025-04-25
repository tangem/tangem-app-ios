//
//  APIHeaderKeyInfo.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct APIHeaderKeyInfo {
    public let headerName: String
    public let headerValue: String

    public init(headerName: String, headerValue: String) {
        self.headerName = headerName
        self.headerValue = headerValue
    }

    var raw: [String: String] {
        [headerName: headerValue]
    }
}
