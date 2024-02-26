//
//  FiatIconURLBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FiatIconURLBuilder {
    private let baseURL: URL

    init(baseURL: URL = URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/")!) {
        self.baseURL = baseURL
    }

    func iconURL(currencyCode: String) -> URL {
        baseURL
            .appendingPathComponent("currencies")
            .appendingPathComponent("medium")
            .appendingPathComponent("\(currencyCode.lowercased()).png")
    }
}
