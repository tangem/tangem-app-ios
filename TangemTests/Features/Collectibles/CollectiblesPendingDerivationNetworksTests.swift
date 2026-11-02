//
//  CollectiblesPendingDerivationNetworksTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemCollectibles
import TangemSdk
import Testing
@testable import Tangem

@Suite("CommonCollectiblesAccountModel.pendingDerivationNetworks")
struct CollectiblesPendingDerivationNetworksTests {
    @Test("Stops asking for the Packs key once it is stored, while the Packs state still waits for a sync")
    func dropsKeyStoredBeforeStateRefresh() {
        let sut = makeSUT(isSyncRequired: true, isPacksKeyStored: false)

        sut.keys.send([Constants.masterKey(isPacksKeyStored: true)])

        #expect(sut.recorder.values == [[Constants.network], []])
    }

    @Test("Does not ask for a missing Packs key while the Packs state needs no sync")
    func ignoresMissingKeyWithoutSync() {
        let sut = makeSUT(isSyncRequired: false, isPacksKeyStored: false)

        #expect(sut.recorder.values == [[]])
    }
}

// MARK: - Helpers

private extension CollectiblesPendingDerivationNetworksTests {
    typealias SUT = (
        keys: CurrentValueSubject<[KeyInfo], Never>,
        recorder: NetworksRecorder
    )

    func makeSUT(isSyncRequired: Bool, isPacksKeyStored: Bool) -> SUT {
        let keys = CurrentValueSubject<[KeyInfo], Never>([Constants.masterKey(isPacksKeyStored: isPacksKeyStored)])
        let publisher = CommonCollectiblesAccountModel.pendingDerivationNetworks(
            network: Constants.network,
            isSyncRequiredPublisher: Just(isSyncRequired).eraseToAnyPublisher(),
            keysPublisher: keys.eraseToAnyPublisher()
        )

        return (keys, NetworksRecorder(publisher: publisher))
    }

    enum Constants {
        static let network = CollectiblesAccountKeyPath.blockchainNetwork(for: .v3)

        static func masterKey(isPacksKeyStored: Bool) -> KeyInfo {
            let chainCode = Data(repeating: 0x33, count: 32)
            let packsKey = ExtendedPublicKey(publicKey: Data(repeating: 0x44, count: 32), chainCode: chainCode)

            return KeyInfo(
                publicKey: Data(repeating: 0x22, count: 32),
                chainCode: chainCode,
                curve: .ed25519_slip0010,
                isImported: false,
                derivedKeys: isPacksKeyStored ? [CollectiblesAccountKeyPath.derivationPath: packsKey] : [:]
            )
        }
    }
}

// MARK: - Doubles

private final class NetworksRecorder {
    private(set) var values: [[BlockchainNetwork]] = []
    private var subscription: AnyCancellable?

    init(publisher: AnyPublisher<[BlockchainNetwork], Never>) {
        subscription = publisher.sink { [weak self] in
            self?.values.append($0)
        }
    }
}
