//
//  TangemPayBankingAccountDepositAddressSigningTask.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemSdk
import TangemPay
import TangemVisa

final class TangemPayBankingAccountDepositAddressSigningTask: CardSessionRunnable {
    func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        runTask(in: self, priority: .userInitiated) { _ in
            var derivationResult: DerivationResult = [:]

            do {
                let customerWalletPath = TangemPayUtilities.derivationPath
                let depositPath = TangemPayUtilities.bankingAccountDerivationPath
                let wallets = session.environment.card?.wallets

                guard let seedKey = wallets?.first(where: { $0.curve == TangemPayUtilities.mandatoryCurve })?.publicKey else {
                    throw Error.derivedKeyNotFound
                }

                let derivationTask = DeriveMultipleWalletPublicKeysTask(
                    [seedKey: [customerWalletPath, depositPath]],
                    shouldFailIfNothingDerived: true
                )
                .withUserWalletRegistration()

                try await derivationTask.prepare(session)
                derivationResult = try await derivationTask.run(in: session)

                guard
                    let customerWalletKey = derivationResult[seedKey]?[customerWalletPath],
                    let depositKey = derivationResult[seedKey]?[depositPath]
                else {
                    throw Error.derivedKeyNotFound
                }

                let customerWalletPublicKey = Wallet.PublicKey(
                    seedKey: seedKey,
                    derivationType: .plain(.init(path: customerWalletPath, extendedPublicKey: customerWalletKey))
                )
                let depositPublicKey = Wallet.PublicKey(
                    seedKey: seedKey,
                    derivationType: .plain(.init(path: depositPath, extendedPublicKey: depositKey))
                )

                let depositAddress = try TangemPayUtilities.makeAddress(using: depositPublicKey)
                let signRequest = try TangemPayUtilities.prepareBankingAccountDepositAddressForSign(depositAddress: depositAddress)

                let signResponse = try await SignHashCommand(
                    hash: signRequest.hash,
                    walletPublicKey: customerWalletPublicKey.seedKey,
                    derivationPath: customerWalletPublicKey.derivationPath
                )
                .run(in: session)

                let unmarshalledSignature = try Secp256k1Signature(with: signResponse.signature).unmarshal(
                    with: customerWalletPublicKey.blockchainKey,
                    hash: signRequest.hash
                )

                completion(.success(Response(
                    result: .success(.init(
                        depositAddress: depositAddress,
                        signature: unmarshalledSignature.data.hexString.lowercased(),
                        derivationResult: derivationResult
                    )),
                    derivationResult: derivationResult
                )))
            } catch {
                VisaLogger.info("Error during banking account deposit address signing. Error: \(error)")
                completion(.success(Response(result: .failure(error), derivationResult: derivationResult)))
            }
        }
    }
}

extension TangemPayBankingAccountDepositAddressSigningTask {
    struct Response {
        let result: Result<TangemPayBankingAccountSigningResponse, Swift.Error>
        let derivationResult: DerivationResult
    }

    enum Error: Swift.Error {
        case derivedKeyNotFound
    }
}
