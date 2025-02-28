//
//  XRPTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import Combine
import CryptoKit
import WalletCore
import TangemSdk
@testable import BlockchainSdk

class XRPTests: XCTestCase {
    func testRoundTripAccountWithDoubleRBase58Encoding() {
        // simulate address with double r
        let buffer = Data(hexString: "000010101010101010101010101010101010101010")
        let checkSum = buffer.getDoubleSha256().prefix(4)
        let account = XRPBase58.getString(from: buffer + checkSum)
        let decodedData = XRPBase58.getData(from: account)!
        // 1 zero byte for network prefix + 20 bytes of address data + 4 bytes of checksum
        let accountData = decodedData.leadingZeroPadding(toLength: 25)
        let accountString = XRPBase58.getString(from: accountData)
        XCTAssertEqual(account, accountString)
    }

    func testAcccountIntoTxEncoding() {
        let account = "rrpCDJ3yxMGC1XPfg1iMRVwsg8a8rar4fa"

        let fieldsWithAccount: [String: Any] = [
            "Account": account,
        ]

        let blobAccount = XRPTransaction(fields: fieldsWithAccount).getBlob()
        XCTAssertEqual(blobAccount, "81140050505050505050505050505050505050505050")

        let fieldsWithDestination: [String: Any] = [
            "Destination": account,
        ]

        let blobDestination = XRPTransaction(fields: fieldsWithDestination).getBlob()
        XCTAssertEqual(blobDestination, "83140050505050505050505050505050505050505050")
    }

    func testXAddressEncode() throws {
        let rAddress = "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf"
        let tag = 4294967294

        let xrpAddress = try XRPAddress(rAddress: rAddress, tag: UInt32(tag))
        XCTAssertEqual(xrpAddress.rAddress, "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf")
        XCTAssertEqual(xrpAddress.xAddress, "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u")

        let xrpAddress2 = try XRPAddress(xAddress: "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u")
        XCTAssertEqual(xrpAddress2.rAddress, "rGWrZyQqhTp9Xu7G5Pkayo7bXjH4k4QYpf")
        XCTAssertEqual(xrpAddress2.xAddress, "XVLhHMPHU98es4dbozjVtdWzVrDjtV1kAsixQTdMjbWi39u")
        XCTAssertEqual(xrpAddress2.tag, 4294967294)
    }

    func testTxSize() throws {
        try testTxSize(curve: .ed25519)
        try testTxSize(curve: .ed25519_slip0010)
    }

    func testTxSize(curve: EllipticCurve) throws {
        // given
        let edPrivateKey = try! Curve25519.Signing.PrivateKey(
            rawRepresentation: Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
        )
        let publicKey = edPrivateKey.publicKey.rawRepresentation

        let transaction = try makeTransaction(publickKey: publicKey, curve: curve)
        let builder = try XRPTransactionBuilder(walletPublicKey: publicKey, curve: curve)
        builder.account = ""
        builder.sequence = 1

        // when
        let (tx, messageToSign) = try builder.buildForSign(transaction: transaction)!

        // then
        TransactionSizeTesterUtility().testTxSize(messageToSign)
    }

    private func makeTransaction(publickKey: Data, curve: EllipticCurve) throws -> Transaction {
        let blockchain = Blockchain.xrp(curve: curve)

        let address = try XRPAddressService(curve: curve).makeAddress(
            for: Wallet.PublicKey(seedKey: publickKey, derivationType: .none),
            with: .default
        )

        return Transaction(
            amount: .init(with: blockchain, value: Decimal(stringValue: "0.5")!),
            fee: .init(.init(with: blockchain, value: Decimal(stringValue: "0.001")!)),
            sourceAddress: address.value,
            destinationAddress: "rDTXLQ7ZKZVKz33zJbHjgVShjsBnqMBhmN", // Random address from explorer
            changeAddress: address.value
        )
    }
}
