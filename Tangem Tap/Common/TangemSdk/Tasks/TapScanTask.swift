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
                        artworkInfo: nil,
                        twinCardInfo: decodeTwinFile(from: self))
    }
    
    private func decodeTwinFile(from response: TapScanTaskResponse) -> TwinCardInfo? {
        guard let fullData = twinIssuerData else {
            return nil
        }
        
        var pairPublicKey: Data?
        if let walletPubKey = card.wallets.first?.publicKey, fullData.count == 129 {
            let pairPubKey = fullData[0..<65]
            let signature = fullData[65..<fullData.count]
            if Secp256k1Utils.verify(publicKey: walletPubKey, message: pairPubKey, signature: signature) ?? false {
                pairPublicKey = pairPubKey
            }
        }
        
        return TwinCardInfo(cid: response.card.cardId,
                            series: TwinCardSeries.series(for: card.cardId),
                            pairCid: TwinCardsUtils.makePairCid(for: response.card.cardId),
                            pairPublicKey: pairPublicKey)
    }
}

//todo: add missing wallets
final class TapScanTask: CardSessionRunnable {
    deinit {
        print("TapScanTask deinit")
    }
    
    private let targetBatch: String?
    
    init(targetBatch: String? = nil) {
        self.targetBatch = targetBatch
    }
    
    /// read -> appendWallets(createwallets+ scan)  -> readTwinData
    public func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let scanTask = ScanTask()
        scanTask.run(in: session) { result in
            switch result {
            case .success(let card):
                
                if let targetBatch = self.targetBatch?.lowercased(),
                   targetBatch.lowercased() != targetBatch {
                    completion(.failure(TangemSdkError.underlying(error: "alert_wrong_card_scanned".localized)))
                    return
                }
                
                self.appendWalletsIfNeeded(card, session: session, completion: completion)
            case.failure(let error):
                return completion(.failure(error))
            }
        }
    }
    
    private func appendWalletsIfNeeded(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        if card.firmwareVersion >= .multiwalletAvailable {
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
            completion(.success(TapScanTaskResponse(card: card, walletData: session.environment.walletData, twinIssuerData: nil)))
            return
        }
        
        let readIssuerDataCommand = ReadIssuerDataCommand(issuerPublicKey: SignerUtils.signerKeys.publicKey)
        readIssuerDataCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):
                completion(.success(TapScanTaskResponse(card: card, walletData: session.environment.walletData, twinIssuerData: response.issuerData)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
