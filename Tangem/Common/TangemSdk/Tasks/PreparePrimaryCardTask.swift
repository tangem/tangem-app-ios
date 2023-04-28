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
    var shouldAskForAccessCode: Bool { false }

    private let seed: Data?
    private var linkingCommand: StartPrimaryCardLinkingTask?

    init(seed: Data?) {
        self.seed = seed
    }

    deinit {
        AppLog.shared.debug("PreparePrimaryCardTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let config = UserWalletConfigFactory(CardInfo(card: CardDTO(card: card), walletData: .none, name: "")).makeConfig()
        let blockchainNetworks = config.defaultBlockchains.map { $0.blockchainNetwork }

        let derivations: [EllipticCurve: [DerivationPath]] = blockchainNetworks.reduce(into: [:]) { result, network in
            if let path = network.derivationPath {
                result[network.blockchain.curve, default: []].append(path)
            }
        }

        var sdkConfig = session.environment.config
        sdkConfig.defaultDerivationPaths = derivations
        session.updateConfig(with: sdkConfig)

        let existingCurves = card.wallets.map { $0.curve }
        let requiredCurves: [EllipticCurve] = card.settings.maxWalletsCount > 1 ? [.secp256k1, .ed25519] : [.secp256k1]
        let curves = requiredCurves.filter { !existingCurves.contains($0) }

        let createWalletsTask = CreateMultiWalletTask(curves: curves, seed: seed)
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
