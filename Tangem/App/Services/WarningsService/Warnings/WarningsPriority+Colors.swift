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
        case .info: return .tangemGrayDark6
        case .warning: return .tangemWarning
        case .critical: return .tangemCritical
        }
    }
    
    var messageColor: Color {
        switch self {
        case .info: return .tangemGrayDark
        default: return .white
        }
    }
}
