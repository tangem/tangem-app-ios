//
//  ScanTaskExtended.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemSdk
import Firebase

struct ScanTaskExtendedResponse: ResponseCodable {
    let card: Card
    let issuerExtraData: ReadIssuerExtraDataResponse?
}

@available(iOS 13.0, *)
final class ScanTaskExtended: CardSessionRunnable {
    public typealias CommandResponse = ScanTaskExtendedResponse
    
    var trace: Trace?
    
    init() {
        trace = Performance.startTrace(name: "CardTapUserTimer")
    }
    
    deinit {
        print("ScanTaskExtended deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
            let scanTask = ScanTask()
            scanTask.run(in: session) { result in
                switch result {
                case .success(let card):
                    self.trace?.stop()
                    if card.cardData?.productMask?.contains(.idCard) ?? false {
                        self.readIssuerExtraData(in: session, for: card, completion: completion)
                    } else {
                        completion(.success(ScanTaskExtendedResponse(card: card, issuerExtraData: nil)))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    @available(iOS 13.0, *)
    private func readIssuerExtraData(in session: CardSession, for card: Card, completion: @escaping CompletionResult<CommandResponse>) {
        let readData = ReadIssuerExtraDataCommand(issuerPublicKey: nil)
        readData.run(in: session) { result in
            switch result {
            case .success(let extraData):
                completion(.success(ScanTaskExtendedResponse(card: card, issuerExtraData: extraData)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
