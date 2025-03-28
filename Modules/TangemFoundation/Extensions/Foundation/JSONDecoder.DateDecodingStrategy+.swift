//
//  JSONDecoder.DateDecodingStrategy+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension JSONDecoder.DateDecodingStrategy {
    /// - Note: Standard `JSONDecoder.DateDecodingStrategy.iso8601` uses `.withInternetDateTime` format of the
    /// `ISO8601DateFormatter` and won't parse milliseconds, see https://stackoverflow.com/a/46538423 for details.
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy = {
        let dateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = .posixEnUS
        
        return .formatted(dateFormatter)
    }()
}
