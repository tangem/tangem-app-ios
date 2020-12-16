//
//  JsonFileReader.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct JsonFileReader {
    
    static func readBundleFile<T: Decodable>(with name: String, type: T.Type, shouldAddCompilationCondition: Bool = true) throws -> T {
        let jsonDecorer = JSONDecoder()
        var suffix: String = ""
        if shouldAddCompilationCondition {
            #if DEBUG
            suffix = "_dev"
            #else
            suffix = "_prod"
            #endif
        }
        guard let path = Bundle.main.url(forResource: name + suffix, withExtension: "json") else {
            throw NSError(domain: "Failed to find json file with name: \(name)", code: -9999, userInfo: nil)
        }
        return try jsonDecorer.decode(type, from: Data(contentsOf: path))
    }
    
}
