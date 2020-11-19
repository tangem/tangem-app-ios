//
//  TwinCardInfo.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum TwinCardSeries: String, CaseIterable {
	case cb61 = "CB61", cb62 = "CB62", cb64 = "CB64", cb65 = "CB65", dev = "BB03"
	
	var number: Int {
		switch self {
		case .cb61, .cb64, .dev: return 1
		case .cb62, .cb65: return 2
		}
	}
	
	static func series(for cardId: String?) -> TwinCardSeries? {
		TwinCardSeries.allCases.first(where: { cardId?.hasPrefix($0.rawValue) ?? false })
	}
}

struct TwinCardInfo {
	let series: TwinCardSeries
	let pairPublicKey: Data?
}
