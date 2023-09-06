//
//  QuotesMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct QuotesMapper {
    func mapToQuotes(_ response: QuotesDTO.Response) -> [Quote] {
        response.quotes.compactMap { key, value in
            guard let price = value.price, let priceChange = value.priceChange24h else {
                return nil
            }

            return Quote(id: key, price: price, priceChange: priceChange)
        }
    }
}
