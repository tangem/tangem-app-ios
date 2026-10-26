//
//  PolymarketFeedCard+Testing.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarketUI
@testable import Tangem

extension PolymarketFeedCard {
    var regularModel: PolymarketEventCard.Model? {
        guard case .regular(let model) = self else {
            return nil
        }

        return model
    }
}
