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

struct ScanTaskExtendedResponse: TlvCodable {
    let card: Card
    let issuerExtraData: ReadIssuerExtraDataResponse?
}

final class ScanTaskExtended: CardSessionRunnable {
    public typealias CommandResponse = ScanTaskExtendedResponse
    
    var trace: Trace?
    
    init() {
        if #available(iOS 13.0, *) {
            trace = Performance.startTrace(name: "CardTapUserTimer")
        } else {
            trace = Performance.startTrace(name: "CardTapUserTimer_legacy")
        }
    }
    
    deinit {
        print("ScanTaskExtended deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        if #available(iOS 13.0, *) {
            trace?.incrementMetric("success", by: 1)
            trace?.stop()
            let scanTask = ScanTask()
            scanTask.run(in: session) { result in
                switch result {
                case .success(let card):
                    if card.cardData?.productMask?.contains(.idCard) ?? false {
                        self.readIssuerExtraData(in: session, for: card, completion: completion)
                    } else {
                        completion(.success(ScanTaskExtendedResponse(card: card, issuerExtraData: nil)))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            let scanTaskLegacy = ScanTaskLegacy()
            scanTaskLegacy.run(in: session) { result in
                self.trace?.incrementMetric("success_legacy", by: 1)
                self.trace?.stop()
                switch result {
                case .success(let card):
                    completion(.success(ScanTaskExtendedResponse(card: card, issuerExtraData: nil)))
                case .failure(let error):
                    completion(.failure(error))
                }
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
