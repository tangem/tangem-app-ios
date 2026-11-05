//
//  AnyTransition+BlurSwap.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension AnyTransition {
    static var blurSwap: AnyTransition {
        if #available(iOS 17.0, *) {
            return AnyTransition(.blurReplace)
        }

        return .opacity
    }
}
