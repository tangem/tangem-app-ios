//
//  Analytics+BlockchainExceptionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Firebase

extension Analytics {
    struct BlockchainExceptionHandler: ExceptionHandlerOutput {
        func handleAPISwitch(currentHost: String, nextHost: String, message: String) {
            Analytics.log(
                event: .blockchainSdkException,
                params: [.exceptionHost: currentHost, .selectedHost: nextHost, .errorDescription: message],
                analyticsSystems: [.crashlytics, .firebase]
            )
        }
    }
}
