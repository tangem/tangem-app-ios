//
//  Publisher+receiveOnMain.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

public extension Publisher {
    func receiveOnMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
}
