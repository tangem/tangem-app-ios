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
    var userTokens: [StorageEntry] {
        userTokensSubject.value
    }

    var userTokensPublisher: AnyPublisher<[StorageEntry], Never> {
        userTokensSubject.eraseToAnyPublisher()
    }

    private let userTokensSubject = CurrentValueSubject<[StorageEntry], Never>([])

    func update(_ type: CommonUserTokenListManager.UpdateType, shouldUpload: Bool) {}

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
