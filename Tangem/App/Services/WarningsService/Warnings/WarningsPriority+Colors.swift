//
//  WarningsPriority+Colors.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

extension WarningPriority {
    var backgroundColor: Color {
        switch self {
        case .info: return Colors.Old.tangemGrayDark6
        case .warning: return Colors.Old.tangemWarning
        case .critical: return Colors.Old.tangemWarning
        }
    }

    var messageColor: Color {
        switch self {
        case .info: return Colors.Old.tangemGrayDark
        default: return .white
        }
    }
}
