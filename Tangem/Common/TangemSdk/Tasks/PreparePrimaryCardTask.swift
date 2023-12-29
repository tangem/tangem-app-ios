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

    private let curves: [EllipticCurve]
    private let shouldReset: Bool
    private let mnemonic: Mnemonic?
    private var commandBag: (any CardSessionRunnable)?

    init(curves: [EllipticCurve], mnemonic: Mnemonic?, shouldReset: Bool) {
        self.curves = curves
        self.shouldReset = shouldReset
        self.mnemonic = mnemonic
    }

    deinit {
        AppLog.shared.debug("PreparePrimaryCardTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if card.settings.isHDWalletAllowed {
            let config = UserWalletConfigFactory(CardInfo(card: CardDTO(card: card), walletData: .none, name: "")).makeConfig()
            let blockchainNetworks = config.defaultBlockchains.map { $0.blockchainNetwork }

            let derivations: [EllipticCurve: [DerivationPath]] = blockchainNetworks.reduce(into: [:]) { result, network in
                result[network.blockchain.curve, default: []].append(contentsOf: network.derivationPaths())
            }

            var sdkConfig = session.environment.config
            sdkConfig.defaultDerivationPaths = derivations
            session.updateConfig(with: sdkConfig)
        }

        if card.wallets.isEmpty {
            createMultiWallet(in: session, completion: completion)
        } else if shouldReset {
            resetCard(in: session, completion: completion)
        } else {
            completion(.failure(.walletAlreadyCreated))
        }
    }

    private func createMultiWallet(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        let command = CreateMultiWalletTask(curves: curves, mnemonic: mnemonic)
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success:
                self.selfcheck(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func selfcheck(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        let command = ReadWalletsListCommand()
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                let validator = InitializedCardValidator(expectedCurves: self.curves)

                if validator.validateWallets(response.wallets) {
                    self.readPrimaryCardIfNeeded(in: session, completion: completion)
                } else {
                    completion(.failure(.walletAlreadyCreated))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func readPrimaryCardIfNeeded(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .backupAvailable, card.settings.isBackupAllowed else {
            completion(.success(.init(card: card, primaryCard: nil)))
            return
        }

        let command = StartPrimaryCardLinkingCommand()
        commandBag = command
        command.run(in: session) { result in
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

    private func resetCard(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        let command = ResetToFactorySettingsTask()
        commandBag = command
        command.run(in: session) { result in
            switch result {
            case .success:
                self.createMultiWallet(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension PreparePrimaryCardTask {
    struct PreparePrimaryCardTaskResponse {
        let card: Card
        let primaryCard: PrimaryCard?
    }
}
