//
//  TokenIconURLBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TokenIconURLBuilder: TokenIconURLBuilding {
    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func iconURL(id: String, size: TokenURLIconSize = .large) -> URL {
        baseURL
            .appendingPathComponent("coins")
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent("\(id).png")
    }
}
