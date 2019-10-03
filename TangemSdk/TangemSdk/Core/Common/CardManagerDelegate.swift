//
//  CardManagerDelegate.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public protocol CardManagerDelegate: class {
    func showSecurityDelay(remainingSeconds: Int)
    func requestPin(completion: @escaping () -> CompletionResult<String>)
}
