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


class CreateMultiWalletTask: CardSessionRunnable {
    typealias CommandResponse = CreateMultiWalletResponse
    
    private lazy var wallets: [Int: WalletConfig] = {
        var dic = [Int: WalletConfig]()
        dic[0] = WalletConfig(isReusable: false,
                              prohibitPurgeWallet: true,
                              curveId: .secp256k1,
                              signingMethods: .signHash)
        
        dic[1] = WalletConfig(isReusable: false,
                              prohibitPurgeWallet: true,
                              curveId: .ed25519,
                              signingMethods: .signHash)
        
        dic[2] = WalletConfig(isReusable: false,
                              prohibitPurgeWallet: true,
                              curveId: .secp256r1,
                              signingMethods: .signHash)
        
        return dic
    }()
    
    private var createWalletResponses: [CreateWalletResponse] = .init()
    
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        createWallet(at: 0, session: session, completion: completion)
    }
    
    private func createWallet(at index: Int, session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let createWalletCommand = CreateWalletCommand(config: wallets[index], walletIndex: index)
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let createWalletResponse):
                self.createWalletResponses.append(createWalletResponse)
                if index == self.wallets.count - 1 {
                    completion(.success(CreateMultiWalletResponse(createWalletResponses: self.createWalletResponses)))
                } else {
                    self.createWallet(at: index + 1, session: session, completion: completion)
                }
            }
        }
    }
    
}
