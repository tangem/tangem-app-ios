//
//  DerivationTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

typealias DerivationTaskResponse = [Data: [ExtendedPublicKey]]

class DerivationTask: CardSessionRunnable {
    private let derivations: [Data: Set<DerivationPath>]
    private var response: DerivationTaskResponse = .init()
    
    init(_ derivations: [Data: Set<DerivationPath>]) {
        self.derivations = derivations
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<DerivationTaskResponse>) {
        self.derive(keys: [Data](derivations.keys), index: 0, in: session, completion: completion)
    }
    
    private func derive(keys: [Data], index: Int, in session: CardSession, completion: @escaping CompletionResult<DerivationTaskResponse>) {
        if index == keys.count {
            completion(.success(response))
            return
        }
        
        let key = keys[index]
        let paths = derivations[key]!
        let task = DeriveWalletPublicKeysTask(walletPublicKey: key, derivationPaths: Array(paths))
        task.run(in: session) { result in
            switch result {
            case .success(let derivedKeys):
                self.response[key] = derivedKeys
                self.derive(keys: keys, index: index + 1, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
