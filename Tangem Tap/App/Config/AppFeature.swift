//
//  AppFeature.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

typealias AppFeatures = Set<AppFeature>

enum AppFeature: String, Option {
	case payIDReceive
	case payIDSend
	case topup
	case pins
	case twinCreation
	case linkedTerminal
}

extension Set where Element == AppFeature {
	static var all: AppFeatures {
		return Set(Element.allCases)
	}
	
	static var none: AppFeatures {
		return Set()
	}
	
	static var allExceptPayReceive: AppFeatures {
		var features = all
		features.remove(.payIDReceive)
		return features
	}
	
	static func allExcept(_ set: AppFeatures) -> AppFeatures {
		var features = all
		set.forEach { features.remove($0) }
		return features
	}
}
