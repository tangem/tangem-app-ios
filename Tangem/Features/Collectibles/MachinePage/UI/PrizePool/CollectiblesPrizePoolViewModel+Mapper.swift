//
//  CollectiblesPrizePoolViewModel+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesPrizePoolViewModel {
    enum Mapper {
        static func map(_ prize: CollectiblesPrize) -> CollectiblesPrizeCard.Model {
            CollectiblesPrizeCard.Model(
                id: prize.id,
                title: prize.name,
                gradeText: prize.grade,
                valueText: prize.insuredValue.map { CollectiblesPriceFormatter.format($0) },
                imageURL: prize.imageURL
            )
        }
    }
}
