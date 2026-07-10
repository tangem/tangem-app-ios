//
//  PreparePrimaryCardTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class PreparePrimaryCardTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private let curves: [EllipticCurve]
    private let shouldReset: Bool
    private let mnemonic: Mnemonic?
    private let passphrase: String?

    private var initializedCard: Card?
    private var primaryCard: PrimaryCard?

    init(curves: [EllipticCurve], mnemonic: Mnemonic?, passphrase: String?, shouldReset: Bool) {
        self.curves = curves
        self.shouldReset = shouldReset
        self.mnemonic = mnemonic
        self.passphrase = passphrase
    }

    deinit {
        AppLogger.debug("PreparePrimaryCardTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if card.settings.isHDWalletAllowed {
            var sdkConfig = session.environment.config
            sdkConfig.defaultDerivationPaths = DefaultDerivationsHelper().makeDefaultDerivations(for: card)
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
        let command = CreateMultiWalletTask(curves: curves, mnemonic: mnemonic, passphrase: passphrase)
        command.run(in: session) { result in
            switch result {
            case .success:
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }

                if card.firmwareVersion >= .v8 {
                    self.createMasterSecret(in: session, completion: completion)
                } else {
                    // save the card with derived wallets
                    self.initializedCard = session.environment.card
                    self.checkIfAllWalletsCreated(in: session, completion: completion)
                }

            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(command) {}
        }
    }

    private func prepateMasterSecret() throws -> ExtendedPrivateKey? {
        guard let mnemonic else { return nil }

        let privKeyFactory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase ?? "")
        let privateKey = try privKeyFactory.makeMasterKey(for: .secp256k1)
        let bip85MasterKey = try privateKey.derivePrivateKey(node: .hardened(83696968))
        return bip85MasterKey
    }

    private func createMasterSecret(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        do {
            let masterSecret = try prepateMasterSecret()
            let command = CreateMasterSecretCommand(privateKey: masterSecret)
            command.run(in: session) { result in
                switch result {
                case .success:
                    // save the card with derived wallets and a master secret
                    self.initializedCard = session.environment.card
                    self.checkMasterSecret(in: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }

                withExtendedLifetime(command) {}
            }
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }

    private func checkMasterSecret(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        let command = ReadMasterSecretCommand()
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                guard response.masterSecret != nil else {
                    completion(.failure(.walletAlreadyCreated))
                    return
                }

                self.checkIfAllWalletsCreated(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(command) {}
        }
    }

    private func checkIfAllWalletsCreated(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .multiwalletAvailable else {
            complete(completion)
            return
        }

        let command = ReadWalletsListCommand()
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                // We can use createWalletCurves for validation here because of the new setup
                let validator = CurvesValidator(expectedCurves: self.curves)

                if validator.validate(response.wallets.map { $0.curve }) {
                    self.readPrimaryCardIfNeeded(in: session, completion: completion)
                } else {
                    completion(.failure(.walletAlreadyCreated))
                }
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(command) {}
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
        command.run(in: session) { result in
            switch result {
            case .success(let primaryCard):
                self.primaryCard = primaryCard
                self.complete(completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(command) {}
        }
    }

    private func resetCard(in session: CardSession, completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        let command = ResetToFactorySettingsTask()
        command.run(in: session) { result in
            switch result {
            case .success:
                self.createMultiWallet(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(command) {}
        }
    }

    private func complete(_ completion: @escaping CompletionResult<PreparePrimaryCardTaskResponse>) {
        guard let card = initializedCard else {
            completion(.failure(.unknownError))
            return
        }

        let response = PreparePrimaryCardTaskResponse(card: card, primaryCard: primaryCard)
        completion(.success(response))
    }
}

extension PreparePrimaryCardTask {
    struct PreparePrimaryCardTaskResponse {
        let card: Card
        let primaryCard: PrimaryCard?
    }
}
