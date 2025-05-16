//
//  VisaWalletModelsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class VisaWalletModelsManager: WalletModelsManager {
    var isInitialized: Bool = false
    var walletModels: [any WalletModel] {
        walletModelsSubject.value
    }

    var walletModelsPublisher: AnyPublisher<[any WalletModel], Never> {
        walletModelsSubject.eraseToAnyPublisher()
    }

    private let keysRepository: KeysRepository

    private let walletModelsSubject = CurrentValueSubject<[any WalletModel], Never>([])
    private var updateAllSubscription: AnyCancellable?
    
    init(keysRepository: KeysRepository) {
        self.keysRepository = keysRepository
    }

    func updateAll(silent: Bool, completion: @escaping () -> Void) {
        let publishers = walletModels.map {
            $0.update(silent: silent)
        }

        updateAllSubscription = Publishers
            .MergeMany(publishers)
            .collect(publishers.count)
            .mapToVoid()
            .receive(on: DispatchQueue.main)
            .receiveCompletion { _ in
                completion()
            }
    }
    
    private func bind() {
        keysRepository.keysPublisher
    }
}
