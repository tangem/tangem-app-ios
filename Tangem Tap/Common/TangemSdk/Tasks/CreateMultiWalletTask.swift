//
//  CreateMultiWalletAndreadtask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CreateMultiWalletResponse: JSONStringConvertible {
    let createWalletResponses: [CreateWalletResponse]
}

struct CreateWalletInfo {
    let index: Int
    let config: WalletConfig
}

class CreateMultiWalletTask: CardSessionRunnable {
    typealias CommandResponse = CreateMultiWalletResponse
    
    public var preflightReadSettings: PreflightReadSettings { .fullCardRead }
    
    private var walletInfos: [CreateWalletInfo]
    private var createWalletResponses: [CreateWalletResponse] = .init()
    
    init(walletInfos: [CreateWalletInfo] = []) {
        self.walletInfos = walletInfos
        
        if self.walletInfos.isEmpty {
            self.walletInfos.append(CreateWalletInfo(index: 0, config: WalletConfig(curveId: .secp256k1)))
            self.walletInfos.append(CreateWalletInfo(index: 1, config: WalletConfig(curveId: .ed25519)))
            self.walletInfos.append(CreateWalletInfo(index: 2, config: WalletConfig(curveId: .secp256r1)))
        }
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        createWallet(at: 0, session: session, completion: completion)
    }
    
    private func createWallet(at index: Int, session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let walletInfo = walletInfos[index]
        let createWalletCommand = CreateWalletCommand(config: walletInfo.config, walletIndex: walletInfo.index)
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let createWalletResponse):
                self.createWalletResponses.append(createWalletResponse)
                if index == self.walletInfos.count - 1 {
                    completion(.success(CreateMultiWalletResponse(createWalletResponses: self.createWalletResponses)))
                } else {
                    self.createWallet(at: index + 1, session: session, completion: completion)
                }
            }
        }
    }
    
}
