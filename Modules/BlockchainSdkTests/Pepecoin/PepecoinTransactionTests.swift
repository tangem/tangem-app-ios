//
//  PepecoinTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

struct PepecoinTransactionTests {
    /// https://pepecoinexplorer.com/address/PgeUfAwdEYgrD8ZG87MVHVg5Hkp94cmAHu/
    @Test(arguments: [BitcoinTransactionBuilder.BuilderType.custom])
    func transaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
        // given
        let pubKey = Data(hexString: "02da14053570364309e696c3d20bdc18a59c6c2b429ee082bfc3fdf168a9c9f0e5")

        let addressService = AddressServiceFactory(blockchain: .pepecoin(testnet: false)).makeAddressService()
        let address = try addressService.makeAddress(from: pubKey, type: .default)
        let unspentOutputManager: UnspentOutputManager = .pepecoin(address: address, isTestnet: false)

        unspentOutputManager.update(
            outputs: [
                .init(blockId: 573409, txId: "8229b1b86dee6d58eecaa472479e203d4644898c7a2cb90c0b327654ec2f6c50", index: 0, amount: 100000000),
            ],
            for: address
        )

        let builder = BitcoinTransactionBuilder(
            network: PepecoinMainnetNetworkParams(), unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .rbf
        )

        let transaction = Transaction(
            amount: Amount(with: .pepecoin(testnet: false), value: Decimal(stringValue: "0.9812416")!),
            fee: Fee(
                .init(with: .pepecoin(testnet: false), value: Decimal(stringValue: "0.0187584")!),
                parameters: BitcoinFeeParameters(rate: 9770)
            ),
            sourceAddress: address.value,
            destinationAddress: "PgeUfAwdEYgrD8ZG87MVHVg5Hkp94cmAHu",
            changeAddress: address.value
        )

        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "fd3d69e06badfb8c3ecd78e7c7f88860061fb3e27104168e776859235e622a3157eb56bb5bb259ddf2acd19e14a040dcce912387813d03d2ba8d50ad6e746e87"),
                publicKey: pubKey,
                hash: Data(hexString: "7bf4fa6d6708525c7b7642a0c7eba7b52d0dfaa8155996a523b28d2fd1314e3a")
            ),
        ]

        // when
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(address.value == "PguLy2qu9JVNAp5gopJgJupo4LsHu1ek5M")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "0100000001506c2fec5476320b0cb92c7a8c8944463d209e4772a4caee586dee6db8b12982000000006b483045022100fd3d69e06badfb8c3ecd78e7c7f88860061fb3e27104168e776859235e622a31022057eb56bb5bb259ddf2acd19e14a040dcce912387813d03d2ba8d50ad6e746e87012102da14053570364309e696c3d20bdc18a59c6c2b429ee082bfc3fdf168a9c9f0e5fdffffff018041d905000000001976a9145fa3e2541fd47a7cc6bb595ae6fbe9e704d3301288ac00000000"))
    }
}
