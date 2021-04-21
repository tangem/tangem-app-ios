//
//  TapScanTask.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

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
    func getCardInfo() -> CardInfo {
        let cardInfo = CardInfo(card: card,
                                artworkInfo: nil,
                                twinCardInfo: nil)
        return cardInfo
    }
}

final class TapScanTask: CardSessionRunnable, PreflightReadCapable {
    let excludeBatches = ["0027",
                          "0030",
                          "0031",
                          "0035"]
    
    var preflightReadSettings: PreflightReadSettings { .fullCardRead }
    
    let excludeIssuers = ["TTM BANK"]
    
    private let unsupportedCardError = TangemSdkError.underlying(error: "alert_unsupported_card".localized)
    
    deinit {
        print("TapScanTask deinit")
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
        
        verifyCard(card, session: session, completion: completion)
    }
    
    private func checkCard(_ card: Card) throws {
        if let product = card.cardData?.productMask, !(product.contains(ProductMask.note) || product.contains(.twinCard)) { //filter product
            throw unsupportedCardError
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
            throw unsupportedCardError
        }
        
        if let issuer = card.cardData?.issuerName, excludeIssuers.contains(issuer) { //filter issuer
            throw unsupportedCardError
        }
    }
    
    private func checkWallets(_ card: Card) throws {
        let wallets = card.wallets
        guard card.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData,
              wallets.count >= 3 else {
            throw unsupportedCardError
        }
        
        let firstWallet = wallets[0]
        guard firstWallet.curve == .secp256k1 || firstWallet.status == .empty else {
            throw unsupportedCardError
        }
        
        let secondWallet = wallets[1]
        guard secondWallet.status == .empty || secondWallet.curve == .ed25519 else {
            throw unsupportedCardError
        }
        
        let thirdWallet = wallets[2]
        guard thirdWallet.status == .empty || thirdWallet.curve == .secp256r1 else {
            throw unsupportedCardError
        }
    }
    
    private func verifyCard(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        VerifyCardCommand().run(in: session) { verifyResult in
            switch verifyResult {
            case .success:
                completion(.success(TapScanTaskResponse(card: card)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
