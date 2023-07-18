//
//  DerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk
import Combine

class CommonDerivationManager {
    weak var delegate: DerivationManagerDelegate?

    private let keysRepository: KeysRepository
    private let userTokenListManager: UserTokenListManager

    private var bag = Set<AnyCancellable>()
    private let _hasPendingDerivations: CurrentValueSubject<Bool, Never> = .init(false)

    private var pendingDerivations: [Data: [DerivationPath]] = [:]

    internal init(keysRepository: KeysRepository, userTokenListManager: UserTokenListManager) {
        self.keysRepository = keysRepository
        self.userTokenListManager = userTokenListManager
        bind()
    }

    private func bind() {
        userTokenListManager.userTokensPublisher
            .combineLatest(keysRepository.keysPublisher)
            .sink { [weak self] entries, keys in
                self?.process(entries, keys)
            }
            .store(in: &bag)
    }

    private func process(_ entries: [StorageEntry], _ keys: [CardDTO.Wallet]) {
        pendingDerivations = [:]

        entries.forEach { entry in
            let curve = entry.blockchainNetwork.blockchain.curve

            guard let derivationPath = entry.blockchainNetwork.derivationPath,
                  let masterKey = keys.first(where: { $0.curve == curve }),
                  !masterKey.derivedKeys.keys.contains(derivationPath) else {
                return
            }

            pendingDerivations[masterKey.publicKey, default: []].append(derivationPath)
        }

        _hasPendingDerivations.send(!pendingDerivations.isEmpty)
    }
}

extension CommonDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        _hasPendingDerivations
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func deriveKeys(cardInteractor: CardDerivable, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard !pendingDerivations.isEmpty else {
            completion(.success(()))
            return
        }

        cardInteractor.deriveKeys(derivations: pendingDerivations) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let response):
                var keys = keysRepository.keys
                for updatedWallet in response {
                    for derivedKey in updatedWallet.value.keys {
                        keys[updatedWallet.key]?.derivedKeys[derivedKey.key] = derivedKey.value
                    }
                }

                // [REDACTED_TODO_COMMENT]
                keysRepository.update(keys: keys)
                delegate?.onDerived(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(cardInteractor) {}
        }
    }
}
