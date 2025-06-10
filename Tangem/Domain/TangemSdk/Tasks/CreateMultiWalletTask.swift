//
//  CreateMultiWalletAndreadtask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CreateMultiWalletTask: CardSessionRunnable {
    private let curves: [EllipticCurve]
    private let mnemonic: Mnemonic?
    private let passphrase: String?

    init(curves: [EllipticCurve] = [.secp256k1, .ed25519], mnemonic: Mnemonic? = nil, passphrase: String? = nil) {
        self.curves = curves
        self.mnemonic = mnemonic
        self.passphrase = passphrase
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if curves.isEmpty {
            completion(.success(.init(cardId: card.cardId)))
            return
        }

        createWallet(at: 0, session: session, completion: completion)
    }

    private func createWallet(at index: Int, session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        let curve = curves[index]
        let createWalletTask: CreateWalletTask
        if let mnemonic = mnemonic {
            do {
                let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase ?? "")
                let privateKey = try factory.makeMasterKey(for: curve)
                createWalletTask = .init(curve: curve, privateKey: privateKey)
            } catch {
                completion(.failure(error.toTangemSdkError()))
                return
            }

        } else {
            createWalletTask = .init(curve: curve)
        }

        createWalletTask.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let createWalletResponse):
                if index == self.curves.count - 1 {
                    completion(.success(SuccessResponse(cardId: createWalletResponse.cardId)))
                } else {
                    self.createWallet(at: index + 1, session: session, completion: completion)
                }
            }
        }
    }
}
