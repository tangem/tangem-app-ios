//
//  TwinCardInfo.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum TwinCardSeries: String, CaseIterable {
	case cb61 = "CB61", cb62 = "CB62", cb64 = "CB64", cb65 = "CB65", dev = "BB03", cb37 = "CB37", cb38 = "CB38"
	
	var number: Int {
		switch self {
		case .cb61, .cb64, .dev, .cb37: return 1
		case .cb62, .cb65, .cb38: return 2
		}
	}
	
	var pair: TwinCardSeries {
		switch self {
		case .cb61: return .cb62
		case .cb62: return .cb61
		case .cb64: return .cb65
		case .cb65: return .cb64
		case .cb37: return .cb38
		case .cb38: return .cb37
		default: return .dev
		}
	}
	
	static func series(for cardId: String?) -> TwinCardSeries? {
		TwinCardSeries.allCases.first(where: { cardId?.hasPrefix($0.rawValue) ?? false })
	}
}

struct TwinCardInfo {
	let series: TwinCardSeries
	let pairCid: String
	let pairPublicKey: Data?
}
