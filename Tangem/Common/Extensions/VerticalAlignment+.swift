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



extension VerticalAlignment {
    private enum TextAndImage: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[.bottom]
        }
    }

    static let textAndImage = VerticalAlignment(TextAndImage.self)
}

extension VerticalAlignment {
    private enum CustomTop: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[VerticalAlignment.top]
        }
    }

    static let customTop = VerticalAlignment(CustomTop.self)
}

extension VerticalAlignment {
    private enum CustomCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[VerticalAlignment.center]
        }
    }

    static let customCenter = VerticalAlignment(CustomCenter.self)
}
