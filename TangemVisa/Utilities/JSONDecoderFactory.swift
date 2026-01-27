//
//  JSONDecoderFactory.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct JSONDecoderFactory {
    func makePayAPIDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }

    func makeCIMDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let locale = Locale(identifier: "en_US_POSIX")

            let formatterA = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
            formatterA.locale = locale
            if let date = formatterA.date(from: dateString) {
                return date
            }

            let formatterB = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS")
            formatterB.locale = locale
            if let date = formatterB.date(from: dateString) {
                return date
            }

            // If neither format works, throw an error
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string does not match expected formats"
            )
        }

        return decoder
    }

    func makeTangemPayAuthorizationServiceDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970 // To parse access tokens expiration date
        return decoder
    }
}
