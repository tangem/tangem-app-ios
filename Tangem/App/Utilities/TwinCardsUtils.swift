//
//  TwinCardsUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct TwinCardsUtils {
	
	static func isCidValid(_ cid: String) -> Bool {
		calculateLuhnRemainder(cid) == 0
	}
	
	static func makePairCid(for cid: String) -> String? {
		guard let twinSeries = TwinCardSeries.series(for: cid) else { return nil }
		
		var cardNumber = cid
		cardNumber.removeFirst(4)
		cardNumber.removeLast()
		
		let pairSeries = twinSeries.pair
		let pairCidWithoutValidation = pairSeries.rawValue + cardNumber
		let validationNumber = calculateTwinPairValidationNumber(for: pairCidWithoutValidation + "\(0)")
		return pairCidWithoutValidation + "\(validationNumber)"
	}
	
	private static func calculateLuhn(for cid: String) -> Int {
		cid.reversed()
			.enumerated()
			.reduce(0, {
				var int = ($1.element.hexDigitValue ?? 0)
				int -= int < 10 ? 0 : 0xA
				if $1.offset % 2 == 0 {
					return $0 + int
				} else {
					let doubled = int * 2
					return $0 + (doubled >= 10 ? doubled - 9 : doubled)
				}
			})
	}
	
	private static func calculateLuhnRemainder(_ cid: String) -> Int {
		calculateLuhn(for: cid) % 10
	}
	
	private static func calculateTwinPairValidationNumber(for cid: String) -> Int {
		let remainder = calculateLuhnRemainder(cid)
		if remainder == 0 { return 0 }
		return 10 - remainder
	}
	
}
