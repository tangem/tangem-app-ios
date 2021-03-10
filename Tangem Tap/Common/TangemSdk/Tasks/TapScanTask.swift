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
//    let verifyResponse: VerifyCardResponse
    let twinIssuerData: Data
//	let files: [File]
	
//	internal init(card: Card, verifyResponse: VerifyCardResponse, files: [File] = []) {
    internal init(card: Card, twinIssuerData: Data = Data()) {
		self.card = card
//		self.files = files
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
        if let walletPubKey = card.walletPublicKey, fullData.count == 129 {
            let pairPubKey = fullData[0..<65]
            let signature = fullData[65..<fullData.count]
            if Secp256k1Utils.vefify(publicKey: walletPubKey, message: pairPubKey, signature: signature) ?? false {
               pairPublicKey = pairPubKey
            }
        }
        
        
//        for file in response.files {
//            do {
//                let twinFile = try twinCardFileDecoder.decode(file)
//                if twinFile.fileTypeName == TwinsWalletCreationService.twinFileName {
//                    pairPublicKey = twinFile.publicKey
//                    break
//                }
//            } catch {
//                print("File doesn't contain twin card dara")
//            }
//        }
    
        return TwinCardInfo(cid: cardId, series: TwinCardSeries.series(for: card.cardId), pairCid: TwinCardsUtils.makePairCid(for: cardId), pairPublicKey: pairPublicKey)
    }
    
    func getCardInfo() -> CardInfo {
        let cardInfo = CardInfo(card: card,
                                artworkInfo: nil,
                                twinCardInfo: decodeTwinFile(from: self))
        return cardInfo
    }
}

final class TapScanTask: CardSessionRunnable {
    let excludeBatches = ["0027",
                          "0030",
                          "0031"] //tangem tags
    
    let excludeIssuers = ["TTM BANK"]
    
    deinit {
        print("TapScanTask deinit")
    }
    
    private unowned var validatedCardsService: ValidatedCardsService
    
    init(validatedCardsService: ValidatedCardsService) {
        self.validatedCardsService = validatedCardsService
    }
    
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
        
        if validatedCardsService.isCardValidated(card) {
            readTwinIssuerDataIfNeeded(card, session: session, completion: completion)
        } else {
            checkWallet(card, session: session, completion: completion)
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
                throw TangemSdkError.cardIsPurged
            }
        }
        
        if let batch = card.cardData?.batchId, self.excludeBatches.contains(batch) { //filter batch
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
        
        if let issuer = card.cardData?.issuerName, excludeIssuers.contains(issuer) { //filter issuer
            throw TangemSdkError.underlying(error: "alert_unsupported_card".localized)
        }
    }
    
    private func checkWallet(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        guard let cardStatus = card.status, cardStatus == .loaded else {
            self.verifyCard(card, session: session, completion: completion)
            return
        }
        
        guard let curve = card.curve,
            let publicKey = card.walletPublicKey else {
                completion(.failure(.cardError))
                return
        }
        
        CheckWalletCommand(curve: curve, publicKey: publicKey, walletIndex: nil).run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                self.verifyCard(card, session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func verifyCard(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        VerifyCardCommand().run(in: session) { verifyResult in
            switch verifyResult {
            case .success:
                self.validatedCardsService.saveValidatedCard(card)
                
                self.readTwinIssuerDataIfNeeded(card, session: session, completion: completion)
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
	
//	private func readFiles(_ card: Card, verifyResponse: VerifyCardResponse, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
//		let filesTask = ReadFilesTask(settings: .init(readPrivateFiles: false))
//		filesTask.run(in: session) { filesResponse in
//			switch filesResponse {
//			case .success(let filesResponse):
//				completion(.success(TapScanTaskResponse(card: card, verifyResponse: verifyResponse, files: filesResponse.files)))
//			case .failure(let error):
//				completion(.failure(error))
//			}
//		}
//	}
}
