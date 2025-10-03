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

            let sanitizedCurrentHost = hostSanitizerUtil.sanitizedHost(from: currentHost)
            let sanitizedNextHost = hostSanitizerUtil.sanitizedHost(from: nextHost)

            Analytics.log(
                event: .blockchainSdkException,
                params: [
                    .exceptionHost: sanitizedCurrentHost,
                    .selectedHost: sanitizedNextHost,
                    .errorDescription: message,
                    .blockchain: blockchainName,
                ]
            )
        }
    }
}
