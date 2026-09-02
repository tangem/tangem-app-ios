//
//  ShtorkaDetents.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct ShtorkaDetents {
    public let collapsed: PresentationDetent
    public let medium: PresentationDetent
    public let full: PresentationDetent

    public init(
        collapsed: PresentationDetent = .height(ShtorkaMetrics.collapsedHeight),
        medium: PresentationDetent = .fraction(0.45),
        full: PresentationDetent = .large
    ) {
        self.collapsed = collapsed
        self.medium = medium
        self.full = full
    }
}
