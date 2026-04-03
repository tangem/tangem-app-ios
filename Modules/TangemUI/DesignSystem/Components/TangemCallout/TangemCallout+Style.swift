//
//  TangemCallout+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Style

extension TangemCallout {
    var textFont: Font { .Tangem.Caption11.semibold }
    var shape: some Shape { .capsule }

    func alignment(arrowAlignment: ArrowAlignment) -> Alignment {
        switch arrowAlignment {
        case .top: .topLeading
        case .bottom: .bottomLeading
        }
    }
}
