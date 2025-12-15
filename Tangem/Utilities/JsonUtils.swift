//
//  JsonUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum JsonUtils {
    static func readBundleFile<T: Decodable>(with name: String, type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        guard let path = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "Failed to find json file with name: \"\(name)\"", code: -9999, userInfo: nil)
        }

        return try decoder.decode(type, from: Data(contentsOf: path))
    }
}
