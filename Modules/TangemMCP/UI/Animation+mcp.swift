//
//  Animation+tokenIcon.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension Animation {
    static var tokenIconAppear: Animation {
        Animation.timingCurve(0.42, 0, 0.58, 1, duration: 0.2).delay(0.55)
    }

    static var mcpFloatingSheetFrameUpdate: Animation {
        Animation.curve(.easeInOutRefined, duration: 0.5)
    }
}
