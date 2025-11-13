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
            let hostFormatter = HostAnalyticsFormatterUtil()

            let formattedCurrentHost = hostFormatter.formattedHost(from: currentHost)
            let formattedNextHost = hostFormatter.formattedHost(from: nextHost)

            Analytics.log(
                event: .blockchainSdkException,
                params: [
                    .exceptionHost: formattedCurrentHost,
                    .selectedHost: formattedNextHost,
                    .errorDescription: message,
                    .blockchain: blockchainName,
                ]
            )
        }
    }
}
