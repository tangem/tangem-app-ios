//
//  StorageType.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum StorageType: String {
	case scannedCards = "tangem_tap_scanned_cards"
	case oldDeviceOldCardAlert = "tangem_tap_oldDeviceOldCard_shown"
	case selectedCurrencyCode = "tangem_tap_selected_currency_code"
	case firstTimeScan = "tangem_tap_first_time_scan"
	case validatedSignedHashesCards = "tangem_tap_validated_signed_hashes_cards"
}
