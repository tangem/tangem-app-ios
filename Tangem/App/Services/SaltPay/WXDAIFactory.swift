//
//  WXDAIFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct WXDAIFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let blockchain: Blockchain
    private let token: Token

    init(blockchain: Blockchain, token: Token) {
        self.blockchain = blockchain
        self.token = token
    }

    private var wxdaiAbi: String? {
        let url = Bundle.main.url(forResource: "abi_wxdai", withExtension: "json")!
        return try? String(contentsOf: url, encoding: .utf8)
    }

    var wxDai: ContractInteractor? {
        guard let wxdaiAbi,
              let rpcURL = blockchain.getJsonRpcURLs(infuraProjectId: keysManager.infuraProjectId)?.first else {
            return nil
        }

        let interactor = ContractInteractor(address: token.contractAddress,
                                            abi: wxdaiAbi,
                                            rpcURL: rpcURL,
                                            decimals: token.decimalCount)

        return interactor
    }
}
