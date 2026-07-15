//
//  BlockchainCodingKeyTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Testing
import CryptoKit
import TangemSdk
import WalletCore
@testable import BlockchainSdk

struct BlockchainCodingKeyTests {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Test
    func codingKeys() throws {
        BlockchainSdk.Blockchain.allMainnetCases.forEach {
            let recoveredFromCodable = try? decoder.decode(Blockchain.self, from: try encoder.encode($0))
            #expect(recoveredFromCodable == $0, "\($0.displayName)")
        }
    }

    @Test
    func robinhoodConfiguration() {
        let mainnet = Blockchain.robinhood(testnet: false)
        let testnet = Blockchain.robinhood(testnet: true)

        #expect(mainnet.chainId == 4663)
        #expect(testnet.chainId == 46630)
        #expect(mainnet.networkId == "robihood")
        #expect(mainnet.coinId == "robinhood-ethereum")
        #expect(mainnet.currencySymbol == "ETH")
        #expect(mainnet.supportsEIP1559)
        #expect(mainnet.isL2EthereumNetwork)

        let mainnetLinks = ExternalLinkProviderFactory().makeProvider(for: mainnet)
        let testnetLinks = ExternalLinkProviderFactory().makeProvider(for: testnet)
        #expect(mainnetLinks.url(transaction: "hash")?.absoluteString == "https://robinhoodchain.blockscout.com/tx/hash")
        #expect(testnetLinks.url(address: "address", contractAddress: nil)?.absoluteString == "https://explorer.testnet.chain.robinhood.com/address/address")
    }
}
