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
    private var derivingCommand: DeriveMultipleWalletPublicKeysTask? = nil
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
            case .success(let primaryCard):
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                if !card.settings.isHDWalletAllowed {
                    let response = PreparePrimaryCardTaskResponse(card: card, primaryCard: primaryCard, derivedKeys: [:])
                    completion(.success(response))
                    return
                }
                
                self.deriveKeys(primaryCard, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func deriveKeys(_ primaryCard: PrimaryCard, in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        let blockchains = SupportedTokenItems().predefinedBlockchains(isDemo: card.isDemoCard)
        
        let derivations: [Data: [DerivationPath]] = blockchains.reduce(into: [:]) { partialResult, blockchain in
            if let wallet = session.environment.card?.wallets.first(where: { $0.curve == blockchain.curve }),
               let path = blockchain.derivationPath(for: card.derivationStyle) {
                partialResult[wallet.publicKey, default: []].append(path)
            }
        }
        
        derivingCommand = DeriveMultipleWalletPublicKeysTask(derivations)
        derivingCommand!.run(in: session) { result in
            switch result {
            case .success(let keys):
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                let response = PreparePrimaryCardTaskResponse(card: card, primaryCard: primaryCard, derivedKeys: keys)
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
