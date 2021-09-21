//
//  TapScanTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TapScanTaskResponse {
    let card: Card
    let walletData: WalletData?
    let twinIssuerData: Data?
    
    func getCardInfo() -> CardInfo {
        return CardInfo(card: card,
                        walletData: walletData,
//                        artworkInfo: nil,
                        twinCardInfo: decodeTwinFile(from: self))
    }
    
    private func decodeTwinFile(from response: TapScanTaskResponse) -> TwinCardInfo? {
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
            if let _ = try? Secp256k1Utils.verify(publicKey: walletPubKey, message: pairPubKey, signature: signature) {
               pairPublicKey = pairPubKey
            }
        }
    
        return TwinCardInfo(cid: response.card.cardId,
                            series: series,
                            pairPublicKey: pairPublicKey)
    }
}

final class TapScanTask: CardSessionRunnable {
    deinit {
        print("TapScanTask deinit")
    }
    
    private let targetBatch: String?
    private var twinIssuerData: Data? = nil
    
    init(targetBatch: String? = nil) {
        self.targetBatch = targetBatch
    }
    
    /// read -> appendWallets(createwallets+ scan)  -> readTwinData
    public func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard let currentBatch = session.environment.card?.batchId.lowercased() else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }
        
        if let targetBatch = self.targetBatch?.lowercased(),
           targetBatch != currentBatch {
            completion(.failure(TangemSdkError.underlying(error: "alert_wrong_card_scanned".localized)))
            return
        }
        
        self.appendWalletsIfNeeded(session: session, completion: completion)
    }
    
    private func appendWalletsIfNeeded(session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let card = session.environment.card!
        
        if card.firmwareVersion >= .multiwalletAvailable, !card.isTangemNote {
            let existingCurves: Set<EllipticCurve> = .init(card.wallets.map({ $0.curve }))
            let mandatoryСurves: Set<EllipticCurve> = [.secp256k1, .ed25519, .secp256r1]
            let missingCurves = mandatoryСurves.subtracting(existingCurves)
            
            if existingCurves.count > 0, // not empty card
               missingCurves.count > 0 //not enough curves
            {
                appendWallets(Array(missingCurves), session: session, completion: completion)
                return
            }
        }
        
        readTwinIssuerDataIfNeeded(card, session: session, completion: completion)
    }
    
    
    private func appendWallets(_ curves: [EllipticCurve], session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        CreateMultiWalletTask(curves: curves).run(in: session) { result in
            switch result {
            case .success:
                self.scanCard(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func scanCard(session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let scanTask = PreflightReadTask(readMode: .fullCardRead, cardId: nil)
        scanTask.run(in: session) { scanCompletion in
            switch scanCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let card):
                self.readTwinIssuerDataIfNeeded(card, session: session, completion: completion)
            }
        }
    }
    
    private func readTwinIssuerDataIfNeeded(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard card.isTwinCard else {
            runAttestation(session, completion)
            return
        }
        
        guard let issuerPubKey = SignerUtils.signerKeys(for: card.issuer.name)?.publicKey else {
            completion(.failure(TangemSdkError.unknownError))
            return
        }
        
        let readIssuerDataCommand = ReadIssuerDataCommand(issuerPublicKey: issuerPubKey)
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
    
    private func runAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let attestationTask = AttestationTask(mode: session.environment.config.attestationMode)
        attestationTask.run(in: session) { result in
            switch result {
            case .success(let report):
                self.processAttestationReport(report, attestationTask, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //[REDACTED_TODO_COMMENT]
    private func processAttestationReport(_ report: Attestation,
                                          _ attestationTask: AttestationTask,
                                          _ session: CardSession,
                                          _ completion: @escaping CompletionResult<TapScanTaskResponse>) {
        switch report.status {
        case .failed, .skipped:
            let isDevelopmentCard = session.environment.card!.firmwareVersion.type == .sdk
            
//            if isDevelopmentCard {
//                self.complete(session, completion)
//                return
//            }
            //Possible production sample or development card
            if isDevelopmentCard || session.environment.config.allowUntrustedCards {
                session.viewDelegate.attestationDidFail(isDevelopmentCard: isDevelopmentCard) {
                    self.complete(session, completion)
                } onCancel: {
                    completion(.failure(.userCancelled))
                }
                
                return
            }
            
            completion(.failure(.cardVerificationFailed))
            
        case .verified:
            self.complete(session, completion)
            
        case .verifiedOffline:
            session.viewDelegate.attestationCompletedOffline() {
                self.complete(session, completion)
            } onCancel: {
                completion(.failure(.userCancelled))
            } onRetry: {
                attestationTask.retryOnline(session) { result in
                    switch result {
                    case .success(let report):
                        self.processAttestationReport(report, attestationTask, session, completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            
        case .warning:
            session.viewDelegate.attestationCompletedWithWarnings {
                self.complete(session, completion)
            }
        }
    }
    
    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<TapScanTaskResponse>) {
        completion(.success(TapScanTaskResponse(card: session.environment.card!,
                                                walletData: session.environment.walletData,
                                                twinIssuerData: twinIssuerData)))
    }
}
