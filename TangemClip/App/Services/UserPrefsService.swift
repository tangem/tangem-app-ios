//
//  UserPrefsService.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class UserPrefsService {
    
    @Storage(type: StorageType.scannedNdefs, defaultValue: [])
    var scannedNdefs: [String]
    
    @Storage(type: StorageType.lastScannedNdef, defaultValue: "")
    var lastScannedNdef: String
    
    @Storage(type: StorageType.searchedCards, defaultValue: [])
    var searchedCards: [String]
    
    deinit {
        print("UserPrefsService deinit")
    }
}

