//
//  YieldModuleDTO+PositionStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension YieldModuleDTO.Response {
    struct PositionInfo: Decodable, Equatable {
        let apy: Decimal

        enum CodingKeys: String, CodingKey {
            case apy
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            guard let apy = try container.decode(FlexibleDecimal.self, forKey: .apy).wrappedValue else {
                throw DecodingError.dataCorruptedError(forKey: .apy, in: container, debugDescription: "apy cannot be converted to Decimal")
            }

            self.apy = apy
        }
    }
}
