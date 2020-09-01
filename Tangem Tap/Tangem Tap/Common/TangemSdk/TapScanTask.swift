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
                if let status = card.status, status == .loaded || status == .empty {
                    self.verifyCard(card, session: session, completion: completion)
                } else {
                    completion(.failure(ScanError.wrongState.toTangemSdkError()))
                }
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
