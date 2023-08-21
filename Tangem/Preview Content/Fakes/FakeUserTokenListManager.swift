//
//  FakeUserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

class FakeUserTokenListManager: UserTokenListManager {
    var userTokens: [StorageEntry.V3.Entry] {
        userTokensSubject.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry.V3.Entry], Never> {
        userTokensSubject.eraseToAnyPublisher()
    }

    var groupingOptionPublisher: AnyPublisher<StorageEntry.V3.Grouping, Never> {
        [
            Just(.none)
                .eraseToAnyPublisher(),
            Just(.byBlockchainNetwork)
                .delay(for: 10.0, scheduler: RunLoop.main)
                .eraseToAnyPublisher(),
        ].merge()
    }

    var sortingOptionPublisher: AnyPublisher<StorageEntry.V3.Sorting, Never> {
        Just(.manual).eraseToAnyPublisher()
    }

    var isInitialSyncPerformed: Bool {
        initialSyncSubject.value
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        initialSyncSubject.eraseToAnyPublisher()
    }

    private let initialSyncSubject = CurrentValueSubject<Bool, Never>(false)
    private let userTokensSubject = CurrentValueSubject<[StorageEntry.V3.Entry], Never>([])
    private let userTokenListSubject = CurrentValueSubject<UserTokenList, Never>(UserTokenListStubs.walletUserWalletList)

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.initialSyncSubject.send(true)
        }
    }

    func update(_ updates: [UserTokenListUpdateType], shouldUpload: Bool) {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let converter = StorageEntriesConverter()
            let blockchainNetwork = BlockchainNetwork(.ethereum(testnet: false))
            let storageEntries = [
                converter.convert(blockchainNetwork),
                converter.convert(.sushiMock, in: blockchainNetwork),
                converter.convert(.shibaInuMock, in: blockchainNetwork),
                converter.convert(.tetherMock, in: blockchainNetwork),
            ]
            self.userTokensSubject.send(storageEntries)
            result(.success(()))
        }
    }

    func updateServerFromLocalRepository() {}
}
