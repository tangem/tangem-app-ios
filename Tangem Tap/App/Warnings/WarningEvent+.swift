//
//  WarningEvent+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension WarningEvent {
    var warning: TapWarning {
        switch self {
        case .numberOfSignedHashesIncorrect:
            return WarningsList.numberOfSignedHashesIncorrect
        }
    }
}
