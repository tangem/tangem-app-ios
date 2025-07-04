//
//  BlockchainDependencies.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct BlockchainSdkDependencies {
    let accountCreator: any AccountCreator
    let dataStorage: any BlockchainDataStorage

    public init(
        accountCreator: any AccountCreator,
        dataStorage: any BlockchainDataStorage
    ) {
        self.accountCreator = accountCreator
        self.dataStorage = dataStorage
    }
}
