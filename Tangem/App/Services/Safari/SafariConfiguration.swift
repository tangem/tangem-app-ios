//
//  SafariConfiguration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SafariConfiguration {
    var dismissButtonStyle: DismissButtonStyle = .close
}

extension SafariConfiguration {
    enum DismissButtonStyle {
        case done
        case close
        case cancel
    }
}
