//
//  PreparePrimaryCardTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk

class PreparePrimaryCardTask: CardSessionRunnable {
    private var derivingCommand: DeriveWalletPublicKeysTask? = nil
    private var linkingCommand: StartPrimaryCardLinkingTask? = nil
    
    func run(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if !card.wallets.isEmpty {
            readPrimaryCard(in: session, completion: completion)
            return
        }
        
        let createWalletsTask = CreateMultiWalletTask()
        createWalletsTask.run(in: session) { result in
            switch result {
            case .success:
                self.readPrimaryCard(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readPrimaryCard(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        linkingCommand = StartPrimaryCardLinkingTask()
        linkingCommand!.run(in: session) { result in
            switch result {
            case .success(let card):
                self.deriveKeys(card, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func deriveKeys(_ primaryCard: PrimaryCard, in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let wallet = session.environment.card?.wallets.first( where: { $0.curve == .secp256k1 }) else {
            completion(.failure(.walletNotFound))
            return
        }
        
        let paths = SupportedTokenItems().predefinedBlockchains.compactMap { $0.derivationPath }
        
        derivingCommand = DeriveWalletPublicKeysTask(walletPublicKey: wallet.publicKey, derivationPaths: paths)
        derivingCommand!.run(in: session) { result in
            switch result {
            case .success(let keys):
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                let response = PreparePrimaryCardTaskResponse(card: card, primaryCard: primaryCard, derivedKeys: [wallet.publicKey: keys])
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension PreparePrimaryCardTask {
    struct PreparePrimaryCardTaskResponse {
        let card: Card
        let primaryCard: PrimaryCard
        let derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]]
    }
}
