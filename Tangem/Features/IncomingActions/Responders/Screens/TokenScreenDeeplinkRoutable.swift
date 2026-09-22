//
//  TokenScreenDeeplinkRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenScreenDeeplinkRoutable: AnyObject {
    func openSwap(parameters: PredefinedSwapParameters)
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters)
}
