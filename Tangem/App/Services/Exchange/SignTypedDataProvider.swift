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
    private let tangemSigner: TangemSigner

    init(
        publicKey: Wallet.PublicKey,
        tangemSigner: TangemSigner
    ) {
        self.publicKey = publicKey
        self.tangemSigner = tangemSigner
    }
}

// MARK: - SignTypedDataProviding

extension SignTypedDataProvider: SignTypedDataProviding {
    func buildPermitSignature(domain: EIP712Domain, message: EIP2612PermitMessage) async throws -> UnmarshalledSignedData {
        let permitModel = try EIP712ModelBuilder().permitTypedData(domain: domain, message: message)
        let data = try JSONEncoder().encode(permitModel)
        print("permitJson:\n" + String(bytes: data, encoding: .utf8)!)
        let signHash = permitModel.signHash
        let signData = try await tangemSigner.sign(hash: signHash, walletPublicKey: publicKey).async()

        let signature = try Secp256k1Signature(with: signData)
        let unmarshalledSig = try signature.unmarshal(with: publicKey.blockchainKey, hash: signHash)

        return UnmarshalledSignedData(v: unmarshalledSig.v, r: unmarshalledSig.r, s: unmarshalledSig.s)
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
