//
//  YieldModuleDTO+Chart.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension YieldModuleDTO {
    enum ChartWindow: String, Decodable {
        case lastMonth = "LAST_MONTH"
        case lastQuarter = "LAST_QUARTER"
        case lastYear = "LAST_YEAR"
    }
}

extension YieldModuleDTO.Response {
    struct Chart: Decodable {
        let underlying: String
        let chainId: Int
        let market: String
        let bucketSizeDays: Int
        let period: YieldModuleDTO.ChartWindow
        let from: String
        let to: String
        let data: [ChartData]
        let avr: Double

        struct ChartData: Decodable {
            let bucketIndex: Int
            let start: Date
            let end: Date
            let avgApy: Decimal

            enum CodingKeys: String, CodingKey {
                case bucketIndex
                case start
                case end
                case avgApy
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                bucketIndex = try container.decode(Int.self, forKey: .bucketIndex)
                start = try container.decode(Date.self, forKey: .start)
                end = try container.decode(Date.self, forKey: .end)

                guard let avgApy = try container.decode(FlexibleDecimal.self, forKey: .avgApy).wrappedValue else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .avgApy,
                        in: container,
                        debugDescription: "avgApy cannot be converted to Decimal"
                    )
                }
                self.avgApy = avgApy
            }
        }
    }
}
