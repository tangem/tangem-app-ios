//
//  DateFormatter+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension DateFormatter {
    convenience init(withFormat format: String, locale: String) {
        self.init()
        dateFormat = format
        self.locale = Locale(identifier: locale)
    }
}
