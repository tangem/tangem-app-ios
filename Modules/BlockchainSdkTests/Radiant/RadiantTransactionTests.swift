//
//  RadiantTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Testing
import TangemFoundation
@testable import BlockchainSdk

final class RadiantTests {
    @Test
    func script() throws {
        // given
        let builder: LockingScriptBuilder = .radiant()

        // when
        let lockScript = try builder.lockingScript(for: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf")

        // then
        #expect(lockScript.data.hex() == "76a9140a2f12f228cbc244c745f33a23f7e924cbf3b6ad88ac".lowercased())
    }

    @Test
    func utils() throws {
        // given
        let converter = ElectrumScriptHashConverter(lockingScriptBuilder: .radiant())

        // when
        let scripthash = try converter.prepareScriptHash(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf")
        let scripthash1 = try converter.prepareScriptHash(address: "166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ")

        // then
        #expect("972C432D04BC6908FA2825860148B8F911AC3D19C161C68E7A6B9BEAE86E05BA" == scripthash)
        #expect("67809980FB38F7685D46A8108A39FE38956ADE259BE1C3E6FECBDEAA20FDECA9" == scripthash1)
    }

    /**
     https://radiantexplorer.com/tx/d9561e19c8e703e6a5bdd3319fa26fd3ccaf268a9532a90bcb92b8fe70d14428
     */
    @Test
    func signRawTransaction() async throws {
        // given
        let blockchain = Blockchain.radiant(testnet: false)
        let publicKey = Data(hexString: "03a6c01a3c551b37488e8dc134ec27197054cbb9d9612b3a5546da7094ba9d36b6")
        let address = try RadiantAddressService().makeAddress(from: publicKey)

        let utxo = [
            UnspentOutput(
                blockId: 313625,
                txId: "f7550a900987a6adce68d8094e1046d4ecd0f6a818cd75a3695edb86d3c06fad",
                index: 0,
                amount: 10000000
            ),
        ]

        let unspentOutputManager: UnspentOutputManager = .radiant(address: address)
        unspentOutputManager.update(outputs: utxo, for: address)
        let txBuilder = try RadiantTransactionBuilder(
            walletPublicKey: publicKey,
            unspentOutputManager: unspentOutputManager,
            decimalValue: blockchain.decimalValue
        )

        let amountValue = Amount(with: blockchain, value: .init(stringValue: "0.05")!)
        let feeValue = Amount(with: blockchain, value: .init(stringValue: "0.0339")!)

        let transaction = Transaction(
            amount: amountValue,
            fee: Fee(feeValue),
            sourceAddress: address.value,
            destinationAddress: "1N3sCSNVGU56pzpJGn6wZPXygPthaD93j2",
            changeAddress: address.value
        )

        let signatures = [
            Data(hexString: "0e25f1476683699d47aab5addac87bdaa81b402a0ef55083a3ec39b6e886cbe5222319881663d2a0db1c60faa157112df5ce874eaa9e2a55f57ae99393980b2c"),
        ]

        // when
        let hashesForSign = try await txBuilder.buildForSign(transaction: transaction)
        let rawTransaction = try await txBuilder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        let expectedHashesForSign = [
            Data(hexString: "dfa716a460390f0f94b23c0ab94b18f635f1aa900653d837ccf4c3f90f3a7265"),
        ]

        let expectedRawTransaction = Data(hexString: "0100000001AD6FC0D386DB5E69A375CD18A8F6D0ECD446104E09D868CEADA68709900A55F7000000006A47304402200E25F1476683699D47AAB5ADDAC87BDAA81B402A0EF55083A3EC39B6E886CBE50220222319881663D2A0DB1C60FAA157112DF5CE874EAA9E2A55F57AE99393980B2C412103A6C01A3C551B37488E8DC134EC27197054CBB9D9612B3A5546DA7094BA9D36B6FFFFFFFF02404B4C00000000001976A914E6E5603A812FD06875A5870A4EF3CE87F3D5403888AC10911800000000001976A914E9AAA640B3A21300D50F332747F7A7F80F13778A88AC00000000")

        #expect(address.value == "1NJWsdLAZcEknx7QQzSTMD9ibVPmevyQL4")
        #expect(hashesForSign == expectedHashesForSign)
        #expect(rawTransaction == expectedRawTransaction)
    }
}
