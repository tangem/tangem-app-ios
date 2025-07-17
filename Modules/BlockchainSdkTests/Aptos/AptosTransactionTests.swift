//
//  AptosTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import Testing
@testable import BlockchainSdk

struct AptosTransactionTests {
    private let coinType: CoinType = .aptos
    /**
     - Use private key for aptos coin at tests in wallet-code aptos
     - Address for sender 0x07968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30
     */
    private let privateKeyData = Data(hexString: "5d996aa76b3212142792d9130796cd2e11e3c445a93118c08414df4f66bc60ec")

    // MARK: - Impementation

    @Test
    func addressNonSignificationZero() throws {
        // given
        let privateKey = PrivateKey(data: privateKeyData)!
        let publicKey = privateKey.getPublicKeyByType(pubkeyType: .ed25519)

        let defaultAddressService = WalletCoreAddressService(coin: coinType)
        let aptosCoreAddressService = AptosCoreAddressService()

        // when
        let defaultAddress = try defaultAddressService.makeAddress(
            for: .init(seedKey: publicKey.data, derivationType: nil),
            with: .default
        )
        let nonsignificantZeroAddress = try aptosCoreAddressService.makeAddress(
            for: .init(seedKey: publicKey.data, derivationType: nil),
            with: .default
        )

        // then
        #expect(nonsignificantZeroAddress.value.removeHexPrefix().count == 64)
        #expect(nonsignificantZeroAddress.value.removeHexPrefix().contains(defaultAddress.value.removeHexPrefix()))
    }

    /**
     - https://github.com/trustwallet/wallet-core/blob/master/tests/chains/Aptos/CompilerTests.cpp
     */
    @Test(.serialized, arguments: [EllipticCurve.ed25519, .ed25519_slip0010])
    func correctCoinTransaction(curve: EllipticCurve) throws {
        // given
        let blockchain = Blockchain.aptos(curve: curve, testnet: true)
        let privateKey = PrivateKey(data: privateKeyData)!
        let publicKey = privateKey.getPublicKeyByType(pubkeyType: .ed25519)

        let transactionBuilder = AptosTransactionBuilder(
            publicKey: publicKey.data,
            decimalValue: blockchain.decimalValue,
            walletAddress: "0x7968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30",
            chainId: .custom(33)
        )

        transactionBuilder.update(sequenceNumber: 99)

        let amount = Amount(with: blockchain, value: 1000 / blockchain.decimalValue)
        let fee = Fee(
            Amount(
                with: blockchain, value: 3296766 / blockchain.decimalValue
            ),
            parameters: AptosFeeParams(gasUnitPrice: 100, maxGasAmount: 3296766)
        )

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: "0x07968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30",
            destinationAddress: "0x07968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30",
            changeAddress: ""
        )

        let expectedBuildForSign = "b5e97db07fa0bd0e5598aa3643a9bc6f6693bddc1a9fec9e674a461eaa00b19307968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f3063000000000000000200000000000000000000000000000000000000000000000000000000000000010d6170746f735f6163636f756e74087472616e7366657200022007968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f3008e803000000000000fe4d3200000000006400000000000000c2276ada0000000021"

        let expectedOutputString = """
            {
                "expiration_timestamp_secs": "3664390082",
                "gas_unit_price": "100",
                "max_gas_amount": "3296766",
                "payload": {
                    "arguments": ["0x7968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30","1000"],
                    "function": "0x1::aptos_account::transfer",
                    "type": "entry_function_payload",
                    "type_arguments": []
                },
                "sender": "0x7968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30",
                "sequence_number": "99",
                "signature": {
                    "public_key": "0xea526ba1710343d953461ff68641f1b7df5f23b9042ffa2d2a798d3adb3f3d6c",
                    "signature": "0x5707246db31e2335edc4316a7a656a11691d1d1647f6e864d1ab12f43428aaaf806cf02120d0b608cdd89c5c904af7b137432aacdd60cc53f9fad7bd33578e01",
                    "type": "ed25519_signature"
                }
            }
        """
        let decoder = JSONDecoder()
        let expectedOutputJson = try decoder.decode(TestSignature.self, from: expectedOutputString.data(using: .utf8) ?? Data())

        // when
        let buildForSign = try transactionBuilder.buildForSign(transaction: transaction, expirationTimestamp: 3664390082)
        let signature = privateKey.sign(digest: buildForSign, curve: .ed25519)
        let buildForSend = try transactionBuilder.buildForSend(transaction: transaction, signature: signature ?? Data(), expirationTimestamp: 3664390082)
        let buildForSendJson = try decoder.decode(TestSignature.self, from: buildForSend)
        let rawSignatureHex = buildForSendJson.signature["signature"]
        let expectedSignatureHex = expectedOutputJson.signature["signature"]

        // then
        // Validate hash size
        TransactionSizeTesterUtility().testTxSizes([signature ?? Data()])
        #expect(rawSignatureHex == expectedSignatureHex)
        #expect(buildForSign.hex() == expectedBuildForSign)
        #expect(signature != nil)
    }
}

extension AptosTransactionTests {
    struct TestSignature: Decodable {
        let signature: [String: String]
    }
}
