//
//  FakeUserTokenListManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeUserTokenListManager: UserTokenListManager {
    var userTokensListPublisher: AnyPublisher<StorageEntriesList, Never> { fatalError() }

    func update(with userTokenList: StorageEntriesList) {
        fatalError()
    }

    var userTokens: [StorageEntry] {
        userTokensSubject.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        userTokensSubject.eraseToAnyPublisher()
    }

    var isInitialSyncPerformed: Bool {
        initialSyncSubject.value
    }

    var initialSyncPublisher: AnyPublisher<Bool, Never> {
        initialSyncSubject.eraseToAnyPublisher()
    }

    var userTokenList: AnyPublisher<UserTokenList, Never> {
        userTokenListSubject
            .delay(for: 3, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private let initialSyncSubject = CurrentValueSubject<Bool, Never>(false)
    private let userTokensSubject = CurrentValueSubject<[StorageEntry], Never>([])
    private let userTokenListSubject = CurrentValueSubject<UserTokenList, Never>(UserTokenListStubs.walletUserWalletList)

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.initialSyncSubject.send(true)
        }
    }

    func update(_ type: UserTokenListUpdateType, shouldUpload: Bool) {}

    func update(with userTokenList: UserTokenList) {
        userTokenListSubject.send(userTokenList)
    }

    func upload() {}

    func updateLocalRepositoryFromServer(result: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.userTokensSubject.send([
                .init(
                    blockchainNetwork: .init(.ethereum(testnet: false)),
                    tokens: [
                        .sushiMock,
                        .shibaInuMock,
                        .tetherMock,
                    ]
                ),
            ])
            result(.success(()))
        }
    }
}
