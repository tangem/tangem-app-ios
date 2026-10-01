//
//  CollectiblesPrizeCard+Model.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesPrizeCard {
    struct Model: Identifiable {
        let id, title: String
        let gradeText, valueText: String?
        let imageURL: URL?
    }
}
