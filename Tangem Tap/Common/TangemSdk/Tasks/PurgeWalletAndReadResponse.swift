//
//  PurgeWalletAndReadResponse.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct PurgeWalletAndReadResponse: JSONStringConvertible {
    let purgeWalletResponse: PurgeWalletResponse
    let card: Card
}

class PurgeWalletAndReadTask: CardSessionRunnable, PreflightReadCapable {
    typealias CommandResponse = PurgeWalletAndReadResponse
    
    public var preflightReadSettings: PreflightReadSettings { .readWallet(index: .index(TangemSdkConstants.oldCardDefaultWalletIndex)) }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let purgeWalletCommand = PurgeWalletCommand(walletIndex: .index(TangemSdkConstants.oldCardDefaultWalletIndex))
        purgeWalletCommand.run(in: session) { purgeWalletCompletion in
            switch purgeWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let purgeWalletResponse):
                let scanTask = PreflightReadTask(readSettings: .fullCardRead)
                scanTask.run(in: session) { scanCompletion in
                    switch scanCompletion {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let scanResponse):
                        completion(.success(PurgeWalletAndReadResponse(purgeWalletResponse: purgeWalletResponse,
                                                                        card: scanResponse)))
                    }
                }
            }
        }
    }
}
