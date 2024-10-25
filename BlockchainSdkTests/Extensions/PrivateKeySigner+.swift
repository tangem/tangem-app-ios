//
//  PrivateKeySigner+.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import WalletCore
@testable import BlockchainSdk

extension PrivateKeySigner: TransactionSigner {
    public func sign(hashes: [Data], walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        .justWithError(output: sign(hashes))
    }

    public func sign(hash: Data, walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        .justWithError(output: sign(hash))
    }
}
