//
//  AppScanTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

enum DefaultWalletData: Codable {
    case file(WalletData)
    case legacy(WalletData)
    case twin(WalletData, TwinData)
    case none

    var twinData: TwinData? {
        if case let .twin(_, data) = self {
            return data
        }

        return nil
    }
}

struct AppScanTaskResponse {
    let card: Card
    let walletData: DefaultWalletData
    let primaryCard: PrimaryCard?

    func getCardInfo() -> CardInfo {
        return CardInfo(card: CardDTO(card: card),
                        walletData: walletData,
                        name: "",
                        primaryCard: primaryCard)
    }
}

final class AppScanTask: CardSessionRunnable {
    let allowsAccessCodeFromRepository: Bool

    private var walletData: DefaultWalletData = .none
    private var primaryCard: PrimaryCard? = nil
    private var linkingCommand: StartPrimaryCardLinkingTask? = nil

    init(allowsAccessCodeFromRepository: Bool) {
        self.allowsAccessCodeFromRepository = allowsAccessCodeFromRepository
    }

    deinit {
        print("AppScanTask deinit")
    }

    /// read ->  readTwinData or note Data or derive wallet's keys -> appendWallets(createwallets+ scan)  -> attestation
    public func run(in session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        if let legacyWalletData = session.environment.walletData,
           legacyWalletData.blockchain != "ANY" {
            self.walletData = .legacy(legacyWalletData)
        }

        self.appendWalletsIfNeeded(session: session, completion: completion)
    }

    private func readExtra(session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let card = session.environment.card!

        if TwinCardSeries.series(for: card.cardId) != nil {
            readTwin(card, session: session, completion: completion)
            return
        }

        if card.firmwareVersion.doubleValue >= 4.39 {
            if card.settings.maxWalletsCount == 1 {
                readFile(card, session: session, completion: completion)
            } else {
                readPrimaryIfNeeded(card, session, completion)
            }

            return
        }

        self.runScanTask(session, completion)
    }

    private func readPrimaryIfNeeded(_ card: Card, _ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let isSaltPayCard = SaltPayUtil().isPrimaryCard(batchId: card.batchId)
        let isWalletInOnboarding = AppSettings.shared.cardsStartedActivation.contains(card.cardId)

        if isSaltPayCard || isWalletInOnboarding,
           card.settings.isBackupAllowed, card.backupStatus == .noBackup {
            readPrimaryCard(session, completion)
            return
        } else {
            deriveKeysIfNeeded(session, completion)
            return
        }
    }

    private func readFile(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        func exit() {
            self.readPrimaryIfNeeded(card, session, completion)
        }

        let readFileCommand = ReadFilesTask(fileName: "blockchainInfo", walletPublicKey: nil)
        readFileCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):
                guard let file = response.first,
                      let tlv = Tlv.deserialize(file.data),
                      let fileSignature = file.signature,
                      let fileCounter = file.counter,
                      let walletData = try? WalletDataDeserializer().deserialize(decoder: TlvDecoder(tlv: tlv)) else {
                    exit()
                    return
                }

                let dataToVerify = Data(hexString: card.cardId) + file.data + fileCounter.bytes4
                let isVerified: Bool = (try? CryptoUtils.verify(curve: .secp256k1,
                                                                publicKey: card.issuer.publicKey,
                                                                message: dataToVerify,
                                                                signature: fileSignature)) ?? false

                guard isVerified else {
                    exit()
                    return
                }

                if walletData.blockchain != "ANY" {
                    self.walletData = .file(walletData)
                }

                exit()
            case .failure(let error):
                switch error {
                case .fileNotFound, .insNotSupported:
                    exit()
                default:
                    completion(.failure(error))
                }
            }
        }
    }

    private func readTwin(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let readIssuerDataCommand = ReadIssuerDataCommand()
        readIssuerDataCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):

                if let walletData = session.environment.walletData {
                    let twinData = self.decodeTwinFile(from: card, twinIssuerData: response.issuerData)
                    self.walletData = .twin(walletData, twinData)
                }

                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }

                self.runScanTask(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func decodeTwinFile(from card: Card, twinIssuerData: Data) -> TwinData {
        var pairPublicKey: Data?

        if let walletPubKey = card.wallets.first?.publicKey, twinIssuerData.count == 129 {
            let pairPubKey = twinIssuerData[0 ..< 65]
            let signature = twinIssuerData[65 ..< twinIssuerData.count]
            if (try? Secp256k1Signature(with: signature).verify(with: walletPubKey, message: pairPubKey)) ?? false {
                pairPublicKey = pairPubKey
            }
        }

        return TwinData(series: TwinCardSeries.series(for: card.cardId)!,
                        pairPublicKey: pairPublicKey)
    }

    private func appendWalletsIfNeeded(session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let card = session.environment.card!

        let existingCurves: Set<EllipticCurve> = .init(card.wallets.map({ $0.curve }))
        let mandatoryCurves: Set<EllipticCurve> = [.secp256k1, .ed25519]
        let missingCurves = mandatoryCurves.subtracting(existingCurves)
        let hasBackup = card.backupStatus?.isActive ?? false

        guard card.settings.maxWalletsCount > 1,
              !hasBackup,
              !existingCurves.isEmpty, !missingCurves.isEmpty else {
            readExtra(session: session, completion: completion)
            return
        }

        appendWallets(Array(missingCurves), session: session, completion: completion)
    }

    private func appendWallets(_ curves: [EllipticCurve], session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        CreateMultiWalletTask(curves: curves).run(in: session) { result in
            switch result {
            case .success:
                self.readExtra(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func readPrimaryCard(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        linkingCommand = StartPrimaryCardLinkingTask()
        linkingCommand!.run(in: session) { result in
            switch result {
            case .success(let primaryCard):
                self.primaryCard = primaryCard
                self.deriveKeysIfNeeded(session, completion)
            case .failure: // ignore any error
                self.deriveKeysIfNeeded(session, completion)
            }
        }
    }

    private func deriveKeysIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let plainCard = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard !plainCard.wallets.isEmpty, plainCard.settings.isHDWalletAllowed else {
            self.runScanTask(session, completion)
            return
        }

        let card = CardDTO(card: plainCard)
        migrate(card: card)
        let config = config(for: card)
        var derivations: [EllipticCurve: [DerivationPath]] = [:]

        if let seed = config.userWalletIdSeed {
            let tokenItemsRepository = CommonTokenItemsRepository(key: UserWalletId(with: seed).stringValue)

            // Force add blockchains for demo cards
            if let persistentBlockchains = config.persistentBlockchains {
                tokenItemsRepository.append(persistentBlockchains)
            }

            let savedItems = tokenItemsRepository.getItems()

            savedItems.forEach { item in
                if let wallet = card.wallets.first(where: { $0.curve == item.blockchainNetwork.blockchain.curve }),
                   let path = item.blockchainNetwork.derivationPath {
                    derivations[wallet.curve, default: []].append(path)
                }
            }
        }

        if derivations.isEmpty {
            self.runScanTask(session, completion)
            return
        }

        var sdkConfig = session.environment.config
        sdkConfig.defaultDerivationPaths = derivations
        session.updateConfig(with: sdkConfig)
        self.runScanTask(session, completion)
    }

    private func runScanTask(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let scanTask = ScanTask()
        scanTask.run(in: session) { result in
            switch result {
            case .success:
                self.complete(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let cardDto = CardDTO(card: card)
        migrate(card: cardDto)

        completion(.success(AppScanTaskResponse(card: card,
                                                walletData: walletData,
                                                primaryCard: primaryCard)))
    }

    private func config(for card: CardDTO) -> UserWalletConfig {
        let cardInfo = CardInfo(card: card, walletData: walletData, name: "")
        return UserWalletConfigFactory(cardInfo).makeConfig()
    }

    private func migrate(card: CardDTO) {
        let config = config(for: card)
        if let legacyCardMigrator = LegacyCardMigrator(cardId: card.cardId, config: config) {
            legacyCardMigrator.migrateIfNeeded()
        }

        if card.hasWallets,
           let seed = config.userWalletIdSeed {
            let userWalletId = UserWalletId(with: seed)
            let tokenMigrator = TokenItemsRepositoryMigrator(card: card, userWalletId: userWalletId.value)
            tokenMigrator.migrate()
        }
    }
}
