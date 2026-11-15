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

    public static func buttons(
        primary: Button,
        secondary: Button? = nil,
        orientation: ButtonGroup.Orientation = .vertical
    ) -> FooterContent {
        switch orientation {
        case .vertical:
            FooterContent(kind: .buttons(primary: primary, secondary: secondary))
        case .horizontal:
            FooterContent(kind: .buttonGroup(ButtonGroup(start: secondary, end: primary).orientation(orientation)))
        }
    }

    public static func signingButton(_ button: SigningActionButtonView, secondary: Button? = nil) -> FooterContent {
        FooterContent(kind: .signingButton(button, secondary: secondary))
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

    public static func toolbar(start: ButtonStack, end: Button) -> FooterContent {
        FooterContent(kind: .toolbarWithStack(buttonStack: start, end: end))
    }

    public static func search(_ search: Search) -> FooterContent {
        FooterContent(kind: .search(search))
    }
}

extension FooterContent {
    enum Kind {
        case buttons(primary: Button, secondary: Button?)
        case buttonGroup(ButtonGroup)
        case signingButton(SigningActionButtonView, secondary: Button?)
        case toolbar(start: Button?, end: Button?)
        case toolbarWithStack(buttonStack: ButtonStack?, end: Button?)
        case search(Search)
    }
}
