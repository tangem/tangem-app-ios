//
//  XRPTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoKit
import WalletCore
import TangemSdk
@testable import BlockchainSdk
import Testing

struct XRPTransactionTests {
    @Test
    func roundTripAccountWithDoubleRBase58Encoding() {
        // simulate address with double r
        let buffer = Data(hexString: "000010101010101010101010101010101010101010")
        let checkSum = buffer.getDoubleSHA256().prefix(4)
        let account = XRPBase58.getString(from: buffer + checkSum)
        let decodedData = XRPBase58.getData(from: account)!
        // 1 zero byte for network prefix + 20 bytes of address data + 4 bytes of checksum
        let accountData = decodedData.leadingZeroPadding(toLength: 25)
        let accountString = XRPBase58.getString(from: accountData)
        #expect(account == accountString)
    }

    @Test
    func acccountIntoTxEncoding() {
        let account = "rrpCDJ3yxMGC1XPfg1iMRVwsg8a8rar4fa"

        let fieldsWithAccount: [String: Any] = [
            "Account": account,
        ]

        let blobAccount = XRPTransaction(fields: fieldsWithAccount).getBlob()
        #expect(blobAccount == "81140050505050505050505050505050505050505050")

        let fieldsWithDestination: [String: Any] = [
            "Destination": account,
        ]

        let blobDestination = XRPTransaction(fields: fieldsWithDestination).getBlob()
        #expect(blobDestination == "83140050505050505050505050505050505050505050")
    }

    @Test
    func xAddressEncode() throws {
        let rAddress = "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf"
        let tag = 4294967294

        let xrpAddress = try XRPAddress(rAddress: rAddress, tag: UInt32(tag))
        #expect(xrpAddress.rAddress == "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf")
        #expect(xrpAddress.xAddress == "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u")

        let xrpAddress2 = try XRPAddress(xAddress: "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u")
        #expect(xrpAddress2.rAddress == "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf")
        #expect(xrpAddress2.xAddress == "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u")
        #expect(xrpAddress2.tag == 4294967294)
    }

    @Test(arguments: [EllipticCurve.ed25519, .ed25519_slip0010])
    func txSize(curve: EllipticCurve) throws {
        // given
        let edPrivateKey = try Curve25519.Signing.PrivateKey(
            rawRepresentation: Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
        )

        let publicKey = edPrivateKey.publicKey.rawRepresentation

        let transaction = try makeTransaction(publickKey: publicKey, curve: curve)
        let builder = try XRPTransactionBuilder(walletPublicKey: publicKey, curve: curve)
        builder.account = ""

        // when
        let (_, messageToSign) = try builder.buildForSign(transaction: transaction, partialPaymentAllowed: false)

        // then
        TransactionSizeTesterUtility().testTxSize(messageToSign)
    }

    private func makeTransaction(publickKey: Data, curve: EllipticCurve) throws -> Transaction {
        let blockchain = Blockchain.xrp(curve: curve)

        let address = try AddressServiceFactory(blockchain: blockchain).makeAddressService().makeAddress(
            for: Wallet.PublicKey(seedKey: publickKey, derivationType: .none),
            with: .default
        )

        return Transaction(
            amount: .init(with: blockchain, value: Decimal(stringValue: "0.5")!),
            fee: .init(.init(with: blockchain, value: Decimal(stringValue: "0.001")!)),
            sourceAddress: address.value,
            destinationAddress: "rDTXLQ7ZKZVKz33zJbHjgVShjsBnqMBhmN", // Random address from explorer
            changeAddress: address.value,
            params: XRPTransactionParams(sequence: 1)
        )
    }

    /// https://xrpscan.com/tx/E71719E6C4C749D53E02AEC361F81F21E94B1ECC1629397EF92899954F5EAA0D
    @Test
    func testOpenTrustlineTransaction() throws {
        // given
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        let feeValue: Decimal = 10
        let fee = Fee(.init(with: blockchain, value: feeValue))

        let signature = Data(hex: "bd3a3697bc3eb8449161ad910100c6a5247eec78495141eb64c44113bf6708671daa361965929a71b881284c865aa8afb747cf3732b4ea34926c0b2dc1e15a09")

        let addressPubKey = Data(hex: "02e3ddda1f4aed8c72f433e23d634b1e525fe677a423fd2d7ae0b898a54dae994f")
        let expectedHash = Data(hex: "1be29053f2774ff10f7ab2fe187900da879692665ee9ccc55715fe6a0adaeb59")
        let expectedSignedBlob = "12001422000200002405CD417B63EC6386F26FC0FFFF5354415242524F00000000000000000000000000D1B4B1F68888A92B5BF9D807A4B434546B89BCC0684000000000989680732102E3DDDA1F4AED8C72F433E23D634B1E525FE677A423FD2D7AE0B898A54DAE994F74473045022100BD3A3697BC3EB8449161AD910100C6A5247EEC78495141EB64C44113BF67086702201DAA361965929A71B881284C865AA8AFB747CF3732B4EA34926C0B2DC1E15A098114A5B4D02116F77D06D993A1D2577329674C4EA6A6"

        let builder = try XRPTransactionBuilder(walletPublicKey: addressPubKey, curve: .secp256k1)
        builder.account = "rGfBamn39dXShmNKTn2ps5tNiCHoowr93D"

        let token = Token(
            name: "STARBRO",
            symbol: "STARBRO",
            contractAddress: "5354415242524F00000000000000000000000000.rLfF6rkXsMvNBYosPmwX2kAGQ5oMtab6dW",
            decimalCount: 0,
            metadata: .init(kind: .fungible)
        )

        let transaction = Transaction(
            amount: .zeroToken(token: token),
            fee: fee,
            sourceAddress: "rGfBamn39dXShmNKTn2ps5tNiCHoowr93D",
            destinationAddress: "rGfBamn39dXShmNKTn2ps5tNiCHoowr93D",
            changeAddress: "",
            contractAddress: token.contractAddress,
            params: XRPTransactionParams(sequence: 97337723)
        )

        // when
        let trustSetTx = try builder.buildTrustSetTransactionForSign(transaction: transaction)
        let (xrpTransaction, hash) = trustSetTx
        let signedTxBlob = try builder.buildForSend(transaction: xrpTransaction, signature: signature)

        // then
        #expect(hash == expectedHash)
        #expect(signedTxBlob == expectedSignedBlob)
    }
}
