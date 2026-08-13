//
//  ExpressCurrency.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressCurrency: Hashable, Codable, Sendable {
    public let contractAddress: String
    public let network: String

    public init(
        contractAddress: String,
        network: String
    ) {
        self.contractAddress = contractAddress
        self.network = network
    }

    public init?(network: String?, contractAddress: String?) {
        guard let network else {
            return nil
        }

        // A `nil` contract address means the native coin
        self.init(contractAddress: contractAddress ?? ExpressConstants.coinContractAddress, network: network)
    }
}
