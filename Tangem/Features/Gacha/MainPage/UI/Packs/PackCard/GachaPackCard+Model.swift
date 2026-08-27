//
//  GachaPackCard+Model.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GachaPackCard {
    struct Model: Identifiable {
        let id, title, priceText: String
        let buybackText: String?
        let artworkURL: URL?
    }
}
