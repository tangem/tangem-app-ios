//
//  SignTypedDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange
import BlockchainSdk
import TangemSdk

struct SignTypedDataProvider {
    internal init(walletManager: WalletManager, tangemSigner: TangemSigner, decimalNumberConverter: DecimalNumberConverting) {
        self.walletManager = walletManager
        self.tangemSigner = tangemSigner
        self.decimalNumberConverter = decimalNumberConverter
    }
    
    let walletManager: WalletManager
    let tangemSigner: TangemSigner
    let decimalNumberConverter: DecimalNumberConverting

    var initialNonce: Int { (walletManager as? EthereumTransactionProcessor)?.initialNonce ?? 0 }

    init(
        walletManager: WalletManager,
        tangemSigner: TangemSigner,
        decimalNumberConverter: DecimalNumberConverting
    ) {
        self.walletManager = walletManager
        self.tangemSigner = tangemSigner
        self.decimalNumberConverter = decimalNumberConverter
    }
}

// MARK: - SignTypedDataProviding

extension SignTypedDataProvider: SignTypedDataProviding {
    func permitData(for currency: Currency, dataModel: SignTypedDataPermitDataModel, deadline: Date) async throws -> String {
        let (v, r, s) = try await signPermitMessage(for: currency, dataModel: dataModel, deadline: deadline)
        let walletAddressAligned = Data(hexString: dataModel.walletAddress)
        let spenderAddressAligned = Data(hexString: dataModel.spenderAddress)
        let nonceAligned = decimalNumberConverter.encoded(value: Decimal(initialNonce), decimalCount: 0)
        let deadlineAligned = decimalNumberConverter.encoded(value: Decimal(Int(deadline.timeIntervalSince1970)), decimalCount: 0)
        let allowedAligned = decimalNumberConverter.encoded(value: Decimal(1), decimalCount: 0)

        let dataParametersForPermit: [Data?] = [
            walletAddressAligned,
            spenderAddressAligned,
            nonceAligned,
            deadlineAligned,
            allowedAligned,
            v,
            r,
            s,
        ]

        let alignedStrings = dataParametersForPermit.compactMap { $0?.aligned(to: 32).hexString }
        let hexString = "0x" + alignedStrings.joined().lowercased()
        print("alignedStrings", alignedStrings)
        print("hexString", hexString)
        print("hexString readable\n", (["0x"] + alignedStrings).joined(separator: "\n").lowercased())
        return hexString
    }
}

private extension SignTypedDataProvider {
    func signPermitMessage(for currency: Currency, dataModel: SignTypedDataPermitDataModel, deadline: Date) async throws -> (v: Data, r: Data, s: Data) {
        let domain = EIP712Domain(
            name: currency.name,
            version: "eth_signTypedData_v4",
            chainId: currency.blockchain.chainId,
            verifyingContract: currency.contractAddress!
        )


        let message = EIP712PermitMessage(
            owner: dataModel.walletAddress,
            spender: dataModel.spenderAddress,
            value: currency.convertFromWEI(value: dataModel.amount).description,
            nonce: initialNonce,
            deadline: Int(deadline.timeIntervalSince1970)
        )

        let permitModel = try EIP712ModelBuilder().permitTypedData(domain: domain, message: message)
        let publicKey = walletManager.wallet.publicKey
        let signHash = permitModel.signHash
        let signData = try await tangemSigner.sign(hash: signHash, walletPublicKey: publicKey).async()

        let signature = try Secp256k1Signature(with: signData)
        let unmarshalledSig = try signature.unmarshal(with: publicKey.blockchainKey, hash: signHash)

        return unmarshalledSig
    }
}
/*
 0x
 0000000000000000000000002c9b2dbdba8a9c969ac24153f5c1c23cb0e63914
 00000000000000000000000011111112542d85b3ef69ae05771c2dccff4faa26
 0000000000000000000000000000000000000000000000000000000000000000
 000000000000000000000000000000000000000000000000000000000b7c3389
 0000000000000000000000000000000000000000000000000000000000000001
 000000000000000000000000000000000000000000000000000000000000001b
 99f49015b499f78912d0ce6a8877292474a4d15fa4a7ebb053746156d38c800b
 0ec53280bccec241b6cba87a5f828aae957fedecab9176a1d215d71e74e0f17b
  */
