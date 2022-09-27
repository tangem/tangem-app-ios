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

    deinit {
        print("PreparePrimaryCardTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let config = GenericConfig(card: card)
        let blockchainNetworks = config.defaultBlockchains.map { $0.blockchainNetwork }

        let derivations: [EllipticCurve: [DerivationPath]] = blockchainNetworks.reduce(into: [:]) { partialResult, blockchainNetwork in
            if let wallet = session.environment.card?.wallets.first(where: { $0.curve == blockchainNetwork.blockchain.curve }),
               let path = blockchainNetwork.derivationPath {
                partialResult[wallet.curve, default: []].append(path)
            }
        }

        var sdkConfig = session.environment.config
        sdkConfig.defaultDerivationPaths = derivations
        session.updateConfig(with: sdkConfig)

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

                let response = PreparePrimaryCardTaskResponse(card: card, primaryCard: primaryCard)
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
    }
}
