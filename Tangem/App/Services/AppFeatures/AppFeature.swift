//
//  AppFeature.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum AppFeature: String, Option {
    case payIDSend
    case topup
    case pins
    case twinCreation
    case linkedTerminal
}

extension Set where Element == AppFeature {
    static var all:  Set<AppFeature> {
        return Set(Element.allCases)
    }

    static var none:  Set<AppFeature> {
        return Set()
    }
}
