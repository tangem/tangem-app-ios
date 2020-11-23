//
//  TwinCardInfo.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum TwinCardSeries: String, CaseIterable {
	case cb61 = "CB61", cb62 = "CB62", cb64 = "CB64", cb65 = "CB65", dev4 = "BB04", dev5 = "BB05"
	
	var number: Int {
		switch self {
		case .cb61, .cb64, .dev4: return 1
		case .cb62, .cb65, .dev5: return 2
		}
	}
	
	var pair: TwinCardSeries {
		switch self {
		case .cb61: return .cb62
		case .cb62: return .cb61
		case .cb64: return .cb65
		case .cb65: return .cb64
		case .dev4: return .dev5
		case .dev5: return .dev4
		}
	}
	
	static func series(for cardId: String?) -> TwinCardSeries? {
		TwinCardSeries.allCases.first(where: { cardId?.hasPrefix($0.rawValue) ?? false })
	}
}

struct TwinCardInfo {
	let cid: String
	let series: TwinCardSeries
	let pairCid: String
	let pairPublicKey: Data?
}
