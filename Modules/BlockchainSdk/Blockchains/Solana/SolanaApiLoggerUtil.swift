//
//  SolanaApiLoggerUtil.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

struct SolanaApiLoggerUtil: NetworkingRouterSwitchApiLogger {
    func handle(error: any Error, currentHost: String, nextHost: String) {
        ExceptionHandler.shared.handleAPISwitch(currentHost: currentHost, nextHost: nextHost, message: error.localizedDescription)
    }

    func handle(error message: String) {
        BSDKLogger.error(error: message)
    }
}
