//
//  UserTokensRepositoryStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

final class UserTokensRepositoryStub: UserTokensRepository {
    private let cryptoAccountSubject: CurrentValueSubject<StoredCryptoAccount, Never>

    var cryptoAccount: StoredCryptoAccount {
        cryptoAccountSubject.value
    }

    var cryptoAccountPublisher: AnyPublisher<StoredCryptoAccount, Never> {
        cryptoAccountSubject.eraseToAnyPublisher()
    }

    init(cryptoAccount: StoredCryptoAccount) {
        cryptoAccountSubject = CurrentValueSubject(cryptoAccount)
    }

    func performBatchUpdates(_ batchUpdates: BatchUpdates) rethrows {
        let batchUpdater = UserTokensRepositoryBatchUpdater()
        try batchUpdates(batchUpdater)

        for update in batchUpdater.updates {
            switch update {
            case .append(let tokens):
                let currentAccount = cryptoAccount
                let currentTokens = currentAccount.tokens
                cryptoAccountSubject.send(
                    currentAccount.withTokens(currentTokens + StoredEntryConverter.convertToStoredEntries(tokens))
                )
            case .remove(let token):
                let currentAccount = cryptoAccount
                let updatedTokens = currentAccount.tokens.filter { $0.toTokenItem() != token }
                cryptoAccountSubject.send(
                    currentAccount.withTokens(updatedTokens)
                )
            case .update(let request):
                let currentAccount = cryptoAccount
                cryptoAccountSubject.send(
                    currentAccount
                        .withTokens(request.tokens)
                        .with(sorting: request.sorting, grouping: request.grouping)
                )
            case .updateBlockchainNetwork(let blockchainNetwork, let tokenItem):
                let currentAccount = cryptoAccount
                let updatedTokens = currentAccount.tokens.map { storedToken in
                    guard storedToken == tokenItem.toStoredToken() else {
                        return storedToken
                    }

                    return storedToken.with(blockchainNetwork: .known(blockchainNetwork: blockchainNetwork))
                }
                cryptoAccountSubject.send(
                    currentAccount.withTokens(updatedTokens)
                )
            }
        }
    }

    func updateLocalRepositoryFromServer(_ completion: @escaping Completion) {
        completion(.success(()))
    }
}
