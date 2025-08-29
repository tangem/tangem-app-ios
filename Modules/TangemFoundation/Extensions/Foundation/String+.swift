//
//  String+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public extension String {
    func base64DecodedData() throws -> Data {
        guard let data = Data(base64Encoded: self) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid Base64 string"))
        }

        return data
    }
}
