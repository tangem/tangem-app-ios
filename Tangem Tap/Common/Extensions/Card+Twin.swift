//
//  Card+Twin.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk

extension Card {
	var isTwinCard: Bool {
		TwinCardSeries.series(for: cardId) != nil
	}
	
	var twinNumber: Int {
		TwinCardSeries.series(for: cardId)?.number ?? 0
	}
}
