//
//  Footer+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct FooterContent {
    let kind: Kind

    public static func buttons(primary: Button, secondary: Button? = nil) -> FooterContent {
        FooterContent(kind: .buttons(primary: primary, secondary: secondary))
    }

    public static func toolbar(start: Button, end: Button) -> FooterContent {
        FooterContent(kind: .toolbar(start: start, end: end))
    }

    public static func toolbar(start: Button) -> FooterContent {
        FooterContent(kind: .toolbar(start: start, end: nil))
    }

    public static func toolbar(end: Button) -> FooterContent {
        FooterContent(kind: .toolbar(start: nil, end: end))
    }

    public static func search(_ search: Search) -> FooterContent {
        FooterContent(kind: .search(search))
    }
}

extension FooterContent {
    enum Kind {
        case buttons(primary: Button, secondary: Button?)
        case toolbar(start: Button?, end: Button?)
        case search(Search)
    }
}
