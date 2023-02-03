//
//  SignTypedDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

protocol SignTypedDataProviding {
    func buildPermitSignature(domain: EIP712Domain, message: EIP2612PermitMessage) async throws -> UnmarshalledSignedData
}

struct SignTypedDataProvider {
    private let publicKey: Wallet.PublicKey
    private let transactionSigner: TransactionSigner

    init(
        publicKey: Wallet.PublicKey,
        transactionSigner: TransactionSigner
    ) {
        self.publicKey = publicKey
        self.transactionSigner = transactionSigner
    }
}

// MARK: - SignTypedDataProviding

extension SignTypedDataProvider: SignTypedDataProviding {
    func buildPermitSignature(domain: EIP712Domain, message: EIP2612PermitMessage) async throws -> UnmarshalledSignedData {
        let permitModel = try EIP712ModelBuilder().permitTypedData(domain: domain, message: message)
        let data = try JSONEncoder().encode(permitModel)
        print("permitJson:\n" + String(bytes: data, encoding: .utf8)!)
        let signHash = permitModel.signHash

        let signData = try await transactionSigner.sign(hash: signHash, walletPublicKey: publicKey).async()
//        let publicKey = oneInchKey()
//        let signData = try Secp256k1Utils().sign(hash: signHash, with: publicKey.blockchainKey)

        let signature = try Secp256k1Signature(with: signData)
        let unmarshalledSig = try signature.unmarshal(with: publicKey.blockchainKey, hash: signHash)

        return UnmarshalledSignedData(v: unmarshalledSig.v, r: unmarshalledSig.r, s: unmarshalledSig.s)
    }

//    func oneInchKey() -> Wallet.PublicKey {
//        let privateKey = Data(hexString: "965e092fdfc08940d2bd05c7b5c7e1c51e283e92c7f52bbf1408973ae9a9acb7")
//        let publicKey = Data(hexString: "04b2eecd54c2c346093076fc8912126d5bf0985aff0e2c17d7d4f6ac885cb65f474fa15046f77257fbff0dae5c41051d8b503b29df2e262468a26a412327b58f0f")
//        // 04b2eecd54c2c346093076fc8912126d5bf0985aff0e2c17d7d4f6ac885cb65f474fa15046f77257fbff0dae5c41051d8b503b29df2e262468a26a412327b58f0f
//        let seedKey = try! Secp256k1Utils().createPublicKey(privateKey: privateKey, compressed: false)
//        return .init(seedKey: seedKey, derivedKey: nil, derivationPath: nil)
//    }
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
