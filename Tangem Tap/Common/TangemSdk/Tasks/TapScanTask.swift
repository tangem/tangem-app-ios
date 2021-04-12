//
//  TapScanTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum ScanError: Error {
    case wrongState
}

struct TapScanTaskResponse: JSONStringConvertible {
    let card: Card
    let twinIssuerData: Data

    internal init(card: Card, twinIssuerData: Data = Data()) {
		self.card = card
        self.twinIssuerData = twinIssuerData
	}
}

extension TapScanTaskResponse {
    private func decodeTwinFile(from response: TapScanTaskResponse) -> TwinCardInfo? {
        guard card.isTwinCard, let cardId = response.card.cardId else {
            return nil
        }
        
        var pairPublicKey: Data?
        let fullData = twinIssuerData
        if let walletPubKey = card.wallets.first?.publicKey, fullData.count == 129 {
            let pairPubKey = fullData[0..<65]
            let signature = fullData[65..<fullData.count]
            if Secp256k1Utils.verify(publicKey: walletPubKey, message: pairPubKey, signature: signature) ?? false {
               pairPublicKey = pairPubKey
            }
        }
    
        return TwinCardInfo(cid: cardId, series: TwinCardSeries.series(for: card.cardId), pairCid: TwinCardsUtils.makePairCid(for: cardId), pairPublicKey: pairPublicKey)
    }
    
    func getCardInfo() -> CardInfo {
        let cardInfo = CardInfo(card: card,
                                artworkInfo: nil,
                                twinCardInfo: decodeTwinFile(from: self))
        return cardInfo
    }
}
//todo: add missing wallets
final class TapScanTask: CardSessionRunnable, PreflightReadCapable {
    var preflightReadSettings: PreflightReadSettings { .fullCardRead }
    
    let excludeBatches = ["0027",
                          "0030",
                          "0031"] //tangem tags
    
    let excludeIssuers = ["TTM BANK"]
    
    deinit {
        print("TapScanTask deinit")
    }
    
    private weak var validatedCardsService: ValidatedCardsService?
    
    init(validatedCardsService: ValidatedCardsService? = nil) {
        self.validatedCardsService = validatedCardsService
    }
    
    
    /// read -> verify -> checkwallet -> appendWallets(createwallets + scan) -> readTwinData or
    /// read -> appendWallets(createwallets+ scan)  -> readTwinData
    public func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        do {
            try checkCard(card)
        } catch let error as TangemSdkError {
            completion(.failure(error))
            return
        } catch { print(error) }
        
        if validatedCardsService?.isCardValidated(card) ?? true {
            appendWalletsIfNeeded(card, session: session, completion: completion)
        } else {
            verifyCard(card, session: session, completion: completion)
        }
    }
    
    private func checkCard(_ card: Card) throws {
        if let product = card.cardData?.productMask, !(product.contains(ProductMask.note) || product.contains(.twinCard)) { //filter product
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
        
        if let status = card.status { //filter status
            if status == .notPersonalized {
                throw TangemSdkError.notPersonalized
            }
            
            if status == .purged {
                throw TangemSdkError.walletIsPurged
            }
        }
        
        if let batch = card.cardData?.batchId, self.excludeBatches.contains(batch) { //filter batch
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
        
        if let issuer = card.cardData?.issuerName, excludeIssuers.contains(issuer) { //filter issuer
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
    }
    
    private func appendWalletsIfNeeded(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        if card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData {
            let existingCurves: Set<EllipticCurve> = Set(card.wallets.compactMap({$0.curve}))
            let mandatoryСurves: Set<EllipticCurve> = [.secp256k1, .ed25519, .secp256r1]
            let missingCurves = mandatoryСurves.subtracting(existingCurves)
            
            if existingCurves.count > 0, // not empty card
               missingCurves.count > 0, //not enough curvse
               let maxIndex = card.walletsCount {
                
                let busyIndexes = card.wallets.filter {$0.status != .empty }.map { $0.index }
                let allIndexes = 0..<maxIndex
                let availableIndexes = allIndexes.filter { !busyIndexes.contains($0) }.sorted()
                
                if availableIndexes.count >= missingCurves.count {
                    var infos: [CreateWalletInfo] = .init()
                    for (index, curve) in missingCurves.enumerated() {
                        infos.append(CreateWalletInfo(index: availableIndexes[index], config: WalletConfig(curveId: curve)))
                    }
                    appendWallets(infos, session: session, completion: completion)
                    return
                }
            }
        }
        
        readTwinIssuerDataIfNeeded(card, session: session, completion: completion)
    }
    
    
    private func appendWallets(_ wallets: [CreateWalletInfo], session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        CreateMultiWalletTask(walletInfos: wallets).run(in: session) { result in
            switch result {
            case .success:
                self.scanCard(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func scanCard(session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let scanTask = PreflightReadTask(readSettings: .fullCardRead)
        scanTask.run(in: session) { scanCompletion in
            switch scanCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let card):
                self.readTwinIssuerDataIfNeeded(card, session: session, completion: completion)
            }
        }
    }
    
    private func checkWallet(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard let cardStatus = card.status, cardStatus == .loaded,
              let major = card.firmwareVersion?.major, major < 4 else {
            self.appendWalletsIfNeeded(card, session: session, completion: completion)
            return
        }
        
        guard let cardWallet = card.wallets.first,
              let curve = cardWallet.curve,
              let publicKey = cardWallet.publicKey else {
                completion(.failure(.cardError))
                return
        }
        
        CheckWalletCommand(curve: curve, publicKey: publicKey).run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                self.appendWalletsIfNeeded(card, session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func verifyCard(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        VerifyCardCommand().run(in: session) { verifyResult in
            switch verifyResult {
            case .success:
                self.validatedCardsService?.saveValidatedCard(card)
                
                self.checkWallet(card, session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readTwinIssuerDataIfNeeded(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard card.isTwinCard else {
            completion(.success(TapScanTaskResponse(card: card)))
            return
        }
        
        let readIssuerDataCommand = ReadIssuerDataCommand(issuerPublicKey: SignerUtils.signerKeys.publicKey)
        readIssuerDataCommand.run(in: session) { (result) in
            switch result {
            case .success(let response):
                completion(.success(TapScanTaskResponse(card: card, twinIssuerData: response.issuerData)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
