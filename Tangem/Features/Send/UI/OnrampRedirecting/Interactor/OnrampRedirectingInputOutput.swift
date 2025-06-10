//
//  OnrampRedirectingInputOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol OnrampRedirectingInput: AnyObject {
    var selectedOnrampProvider: OnrampProvider? { get }
}

protocol OnrampRedirectingOutput: AnyObject {
    func redirectDataDidLoad(data: OnrampRedirectData)
}
