//
//  WarningsPriority+Colors.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

extension WarningPriority {
    var backgroundColor: Color {
        switch self {
        case .info: return .tangemTapGrayDark6
        case .warning: return .tangemTapWarning
        case .critical: return .tangemTapCritical
        }
    }
    
    var messageColor: Color {
        switch self {
        case .info: return .tangemTapGrayDark
        default: return .white
        }
    }
}
