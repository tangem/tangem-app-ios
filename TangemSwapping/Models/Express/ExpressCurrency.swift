//
//  ExpressCurrency.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressCurrency: Hashable, Codable {
    public let contractAddress: String
    public let network: String

    public init(contractAddress: String, network: String) {
        self.contractAddress = contractAddress
        self.network = network
    }

    internal init(response: ExpressDTO.Assets.Response) {
        contractAddress = response.contractAddress
        network = response.network
    }
}
