//
//  TokenIconUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TokenIconURLBuilder {
    enum IconSize: String {
        /// 50x50
        case small
        /// 250x250
        case large
    }

    func iconURL(id: String, size: IconSize = .large) -> URL {
        CoinsResponse.baseURL
            .appendingPathComponent("coins")
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent("\(id).png")
    }
}
