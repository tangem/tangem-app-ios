//
//  TransactionSendResult.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct TransactionSendResult: Hashable {
    public let hash: String
    public let currentProviderHost: String

    init(hash: String, currentProviderHost: String) {
        self.hash = hash
        self.currentProviderHost = currentProviderHost
    }
}

public struct SendTxError: UniversalError {
    public let error: UniversalError
    public let tx: String?
    public let lastRetryHost: String?

    public var errorDescription: String? {
        error.localizedDescription
    }

    public var errorCode: Int {
        error.errorCode
    }

    var description: String {
        """
            description: \(error.localizedDescription)
            tx: \(tx ?? "undefined")
            lastRetryHost: \(lastRetryHost ?? "undefined")
        """
    }

    public var formattedLastRetryHost: String? {
        HostAnalyticsFormatterUtil().formattedHost(from: lastRetryHost ?? "")
    }

    // MARK: - Init

    public init(error: UniversalError, tx: String? = nil, lastRetryHost: String? = nil) {
        self.error = error
        self.tx = tx
        self.lastRetryHost = lastRetryHost
    }
}
