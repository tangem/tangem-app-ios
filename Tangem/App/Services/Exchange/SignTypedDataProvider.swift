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
    let walletManager: WalletManager
    let tangemSigner: TangemSigner

    init(walletManager: WalletManager, tangemSigner: TangemSigner) {
        self.walletManager = walletManager
        self.tangemSigner = tangemSigner
    }
}

extension SignTypedDataProvider: SignTypedDataProviding {
    func permitData(for currency: Currency, dataModel: SignTypedDataPermitDataModel, deadline: Date) async throws -> String {
        let domain = EIP712Domain(
            name: currency.name,
            version: "signTypedData_v4",
            chainId: currency.blockchain.chainId,
            verifyingContract: currency.contractAddress!
        )

        let message = EIP712PermitMessage(
            owner: dataModel.walletAddress,
            spender: dataModel.spenderAddress,
            value: currency.convertFromWEI(value: dataModel.amount).description,
            nonce: (walletManager as! EthereumTransactionProcessor).initialNonce,
            deadline: Int(deadline.timeIntervalSince1970)
        )

        let permitModel = try EIP712ModelBuilder().permitTypedData(domain: domain, message: message)
        let data = permitModel.signHash
        let publicKey = walletManager.wallet.publicKey
        let signData = try await tangemSigner.sign(hash: data, walletPublicKey: publicKey).async()

        let unmarshalledSig = try Secp256k1Signature(with: signData).unmarshal(with: publicKey.blockchainKey, hash: data)
        let string = "0x" + unmarshalledSig.r.hexString + unmarshalledSig.s.hexString + unmarshalledSig.v.hexString

        print("hexString", string)
        return string
    }
}
