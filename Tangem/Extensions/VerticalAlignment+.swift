//
//  FirstBaselignAlignment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension VerticalAlignment {
    private enum FirstBaselineCustomAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[.firstTextBaseline]
        }
    }

    static let firstBaselineCustom = VerticalAlignment(FirstBaselineCustomAlignment.self)
}
