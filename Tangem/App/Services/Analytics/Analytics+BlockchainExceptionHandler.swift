//
//  BlockchainExceptionHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Firebase
import SwiftDate

extension Analytics {
    struct BlockchainExceptionHandler: ExternalExceptionHandler {
        
        // MARK: - Properties

        private(set) var blockchain: Blockchain

        // MARK: - Implementation

        func errorSwitchApi(exceptionHost: String, selectedHost: String?, code: Int, message: String) {
            Analytics.log(
                event: .blockchainSdkException,
                params: [
                    .blockchain: blockchain.currencySymbol,
                    .region: Locale.current.regionCode?.lowercased() ?? "",
                    .exceptionHost: exceptionHost,
                    .selectedHost: selectedHost ?? "",
                    .errorCode: "\(code)",
                    .errorDescription: message,
                ],
                analyticsSystems: [.crashlytics]
            )
        }
    }
}
