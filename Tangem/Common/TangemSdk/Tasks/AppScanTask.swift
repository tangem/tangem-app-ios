//
//  AppScanTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
#if !CLIP
import BlockchainSdk
#endif

struct AppScanTaskResponse {
    let card: Card
    let walletData: WalletData?
    let twinIssuerData: Data?
    let isTangemNote: Bool //todo refactor
    let isTangemWallet: Bool
    let derivedKeys: [Data: [DerivationPath:ExtendedPublicKey]]
    let primaryCard: PrimaryCard?
    
    func getCardInfo() -> CardInfo {
        return CardInfo(card: card,
                        walletData: walletData,
                        //                        artworkInfo: nil,
                        twinCardInfo: decodeTwinFile(from: self),
                        isTangemNote: isTangemNote,
                        isTangemWallet: isTangemWallet,
                        derivedKeys: derivedKeys,
                        primaryCard: primaryCard)
    }
    
    private func decodeTwinFile(from response: AppScanTaskResponse) -> TwinCardInfo? {
        guard
            card.isTwinCard,
            let series: TwinCardSeries = .series(for: card.cardId)
        else {
            return nil
        }
        
        var pairPublicKey: Data?
        
        if let walletPubKey = card.wallets.first?.publicKey, let fullData = twinIssuerData, fullData.count == 129 {
            let pairPubKey = fullData[0..<65]
            let signature = fullData[65..<fullData.count]
            if (try? Secp256k1Signature(with: signature).verify(with: walletPubKey, message: pairPubKey)) ?? false {
                pairPublicKey = pairPubKey
            }
        }
        
        return TwinCardInfo(cid: response.card.cardId,
                            series: series,
                            pairPublicKey: pairPublicKey)
    }
}

enum AppScanTaskError: String, Error, LocalizedError {
    case wrongCardClip
    
    var errorDescription: String? {
        "alert_wrong_card_scanned".localized
    }
}

final class AppScanTask: CardSessionRunnable {
    private let userPrefsService: UserPrefsService?
    
    private let targetBatch: String?
    private var twinIssuerData: Data? = nil
    private var noteWalletData: WalletData? = nil
    private var primaryCard: PrimaryCard? = nil
    private var derivedKeys: [Data: [DerivationPath:ExtendedPublicKey]] = [:]
    private var linkingCommand: StartPrimaryCardLinkingTask? = nil
#if !CLIP
    private let tokenItemsRepository: TokenItemsRepository?
    
    init(tokenItemsRepository: TokenItemsRepository?, userPrefsService: UserPrefsService?,
         targetBatch: String? = nil) {
        self.tokenItemsRepository = tokenItemsRepository
        self.targetBatch = targetBatch
        self.userPrefsService = userPrefsService
    }
#else
    init(userPrefsService: UserPrefsService?, targetBatch: String? = nil) {
        self.targetBatch = targetBatch
        self.userPrefsService = userPrefsService
    }
#endif
    
    deinit {
        print("AppScanTask deinit")
    }
    
    /// read ->  readTwinData or note Data or derive wallet's keys -> appendWallets(createwallets+ scan)  -> attestation
    public func run(in session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }
        
        let currentBatch = card.batchId.lowercased()
        
        if let targetBatch = self.targetBatch?.lowercased(),
           targetBatch != currentBatch {
            completion(.failure(TangemSdkError.underlying(error: AppScanTaskError.wrongCardClip)))
            return
        }
        
        self.readExtra(card, session: session, completion: completion)
    }
    
    private func readExtra(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        if card.isTwinCard {
            readTwin(card, session: session, completion: completion)
            return
        }
        
        if card.firmwareVersion.doubleValue >= 4.39 {
            if card.settings.maxWalletsCount == 1 {
                readNote(card, session: session, completion: completion)
                return
            }
            
            if let userPrefsService = self.userPrefsService,
               userPrefsService.cardsStartedActivation.contains(card.cardId),
               card.backupStatus == .noBackup {
                readPrimaryCard(session, completion)
                return
            } else {
                deriveKeysIfNeeded(session, completion)
                return
            }
            
        }
        
        runAttestation(session, completion)
    }
    
    private func readNote(_ card: Card, session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        // self.noteWalletData = WalletData(blockchain: "BTC") //for test without file
        // self.runAttestation(session, completion)
        // return
        
        func exit() {
            self.noteWalletData = nil
            self.deriveKeysIfNeeded(session, completion)
        }
        
        let readFileCommand = ReadFilesTask(fileName: "blockchainInfo", walletPublicKey: nil)
        readFileCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):
                guard let file = response.first,
                      let namedFile = try? NamedFile(tlvData: file.data),
                      let tlv = Tlv.deserialize(namedFile.payload),
                      let fileSignature = namedFile.signature,
                      let fileCounter = namedFile.counter,
                      let walletData = try? WalletDataDeserializer().deserialize(decoder: TlvDecoder(tlv: tlv)) else {
                    exit()
                    return
                }
                
                let dataToVerify = Data(hexString: card.cardId) + namedFile.payload + fileCounter.bytes4
                let isVerified: Bool = (try? CryptoUtils.verify(curve: .secp256k1,
                                                                publicKey: card.issuer.publicKey,
                                                                message: dataToVerify,
                                                                signature: fileSignature)) ?? false
                
                guard isVerified else {
                    exit()
                    return
                }
                
                self.noteWalletData = walletData
                self.runAttestation(session, completion)
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
                self.twinIssuerData = response.issuerData
                
                guard session.environment.card != nil else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func appendWalletsIfNeeded(session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let card = session.environment.card!
        
        let existingCurves: Set<EllipticCurve> = .init(card.wallets.map({ $0.curve }))
        let mandatoryСurves: Set<EllipticCurve> = [.secp256k1, .ed25519]
        let missingCurves = mandatoryСurves.subtracting(existingCurves)
        
        if !existingCurves.isEmpty, // not empty card
           !missingCurves.isEmpty //not enough curves
        {
            appendWallets(Array(missingCurves), session: session, completion: completion)
            return
        }
        
        deriveKeysIfNeeded(session, completion)
    }
    
    private func appendWallets(_ curves: [EllipticCurve], session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        CreateMultiWalletTask(curves: curves).run(in: session) { result in
            switch result {
            case .success:
                self.runAttestation(session, completion)
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
            case .failure: //ignore any error
                self.deriveKeysIfNeeded(session, completion)
            }
        }
    }
    
    private func deriveKeysIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
#if CLIP
        self.runAttestation(session, completion)
        return
#else
        guard let tokenItemsRepository = self.tokenItemsRepository,
        session.environment.card?.settings.isHDWalletAllowed == true else {
            self.runAttestation(session, completion)
            return
        }
        
        
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if card.isDemoCard { //Force add blockchains for demo cards
            let demoBlockchains = SupportedTokenItems().predefinedBlockchains(isDemo: true)
            tokenItemsRepository.append(demoBlockchains, for: card.cardId, style: card.derivationStyle)
        }
        
        let savedItems = tokenItemsRepository.getItems(for: card.cardId)
        
        var derivations: [Data : Set<DerivationPath>] = [:]
        savedItems.forEach { item in
            if let wallet = card.wallets.first(where: { $0.curve == item.blockchainNetwork.blockchain.curve }),
               let path = item.blockchainNetwork.derivationPath {
                derivations[wallet.publicKey, default: []].insert(path)
            }
        }
        
        if derivations.isEmpty {
            self.runAttestation(session, completion)
            return
        }
        
        DeriveMultipleWalletPublicKeysTask(derivations.mapValues{Array($0)})
            .run(in: session) { result in
            switch result {
            case .success(let derivedKeys):
                self.derivedKeys = derivedKeys
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
#endif
    }
    
    private func runAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let attestationTask = AttestationTask(mode: session.environment.config.attestationMode)
        attestationTask.run(in: session) { result in
            switch result {
            case .success:
                self.complete(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<AppScanTaskResponse>) {
        let card = session.environment.card!
        let isNote = noteWalletData != nil
        let isWallet = card.firmwareVersion.doubleValue >= 4.39 && !isNote && card.settings.maxWalletsCount > 1
        
        completion(.success(AppScanTaskResponse(card: session.environment.card!,
                                                walletData: noteWalletData ?? session.environment.walletData,
                                                twinIssuerData: twinIssuerData,
                                                isTangemNote: noteWalletData != nil,
                                                isTangemWallet: isWallet,
                                                derivedKeys: derivedKeys,
                                                primaryCard: primaryCard)))
    }
}
