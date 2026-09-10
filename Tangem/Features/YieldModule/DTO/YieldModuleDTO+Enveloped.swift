//
//  YieldModuleDTO+Enveloped.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension YieldModuleDTO {
    /// Unwraps the `{success, timestamp, result}` envelope of the `/yield-modules/*` endpoints.
    /// Tolerates a bare payload so a backend rollout without the envelope keeps decoding.
    struct Enveloped<T: Decodable>: Decodable {
        let result: T

        init(from decoder: Decoder) throws {
            let container = try? decoder.container(keyedBy: CodingKeys.self)

            guard let container, container.contains(.result) else {
                result = try T(from: decoder)
                return
            }

            if let success = try container.decodeIfPresent(Bool.self, forKey: .success), !success {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Yield module API reported success = false"
                    )
                )
            }

            result = try container.decode(T.self, forKey: .result)
        }

        private enum CodingKeys: String, CodingKey {
            case success
            case result
        }
    }
}
