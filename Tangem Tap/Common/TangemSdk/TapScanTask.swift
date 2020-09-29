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

struct TapScanTaskResponse: ResponseCodable {
    let card: Card
    let verifyResponse: VerifyCardResponse
}

final class TapScanTask: CardSessionRunnable {
    let excludeBatches = ["0027", "0030", "0031"]
    
    var needPreflightRead: Bool {
        return false
    }
    
    deinit {
        print("TapScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let scanTask = ScanTask()
        scanTask.run(in: session) { result in
            switch result {
            case .success(let card):
                if let product = card.cardData?.productMask, !product.contains(ProductMask.note) { //filter product
                    completion(.failure(TangemSdkError.underlying(error: "alert_unsupported_card".localized)))
                    return
                }
                
                if let status = card.status { //filter status
                    if status == .notPersonalized {
                        completion(.failure(TangemSdkError.notPersonalized))
                        return
                    }
                    
                    if status == .purged {
                        completion(.failure(TangemSdkError.cardIsPurged))
                        return
                    }
                }
                
                if let batch = card.cardData?.batchId, self.excludeBatches.contains(batch) { //filter bach
                    completion(.failure(TangemSdkError.underlying(error: "alert_unsupported_card".localized)))
                    return
                }
                
                self.verifyCard(card, session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func verifyCard(_ card: Card, session: CardSession, completion: @escaping CompletionResult<TapScanTaskResponse>) {
        let verifyCommand = VerifyCardCommand(onlineVerification: true)
        verifyCommand.run(in: session) { verifyResult in
            switch verifyResult {
            case .success(let verifyResponse):
                completion(.success(TapScanTaskResponse(card: card, verifyResponse: verifyResponse)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
