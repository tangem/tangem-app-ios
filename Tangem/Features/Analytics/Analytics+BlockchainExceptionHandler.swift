//
//  Analytics+BlockchainExceptionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

extension Analytics {
    struct BlockchainExceptionHandler: ExceptionHandlerOutput {
        func handleAPISwitch(currentHost: String, nextHost: String, message: String, blockchainName: String) {
            let hostSanitizerUtil = HostSanitizerUtil()

            let sanitizeCurrentHost = hostSanitizerUtil.sanitizedHost(from: currentHost)
            let sanitizeNextHost = hostSanitizerUtil.sanitizedHost(from: nextHost)

            Analytics.log(
                event: .blockchainSdkException,
                params: [
                    .exceptionHost: sanitizeCurrentHost,
                    .selectedHost: sanitizeNextHost,
                    .errorDescription: message,
                    .blockchain: blockchainName,
                ]
            )
        }
    }
}
