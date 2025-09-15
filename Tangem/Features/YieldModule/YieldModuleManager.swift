//
//  YieldModuleManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine

protocol YieldModuleManager {
    var yieldWalletManagers: [TokenItem: YieldModuleWalletManager] { get }
    var yieldWalletManagersPublisher: AnyPublisher<[TokenItem: YieldModuleWalletManager], Never> { get }
}

final class CommonYieldModuleManager {
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    private let walletModelsManager: WalletModelsManager
    private let userWalletId: UserWalletId

    private let _yieldWalletManagers = CurrentValueSubject<[TokenItem: YieldModuleWalletManager], Never>([:])

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
    ) {
        self.walletModelsManager = walletModelsManager
        self.userWalletId = userWalletId

        bind()
    }
}

extension CommonYieldModuleManager: YieldModuleManager {
    var yieldWalletManagers: [TokenItem: any YieldModuleWalletManager] {
        _yieldWalletManagers.value
    }

    var yieldWalletManagersPublisher: AnyPublisher<[TokenItem: any YieldModuleWalletManager], Never> {
        _yieldWalletManagers.eraseToAnyPublisher()
    }
}

private extension CommonYieldModuleManager {
    func bind() {
        let walletModelsPublisher = walletModelsManager
            .walletModelsPublisher
            .removeDuplicates()

        walletModelsPublisher
            .flatMapLatest { walletModels in
                walletModels
                    .map { walletModel in
                        walletModel
                            .featuresPublisher
                            .map { (walletModel, $0) }
                    }
                    .merge()
                    // Debounced `collect` is used to collect all outputs from an undetermined number of wallet models with features
                    .collect(debouncedTime: 1.0, scheduler: DispatchQueue.main)
            }
            .map { [currentYieldWalletManagers = _yieldWalletManagers.value] features in
                return features.reduce(into: [TokenItem: YieldModuleWalletManager]()) { partialResult, element in
                    let (walletModel, features) = element
                    let factory = features.compactMap(\.yieldModuleFactory).first
                    partialResult[walletModel.tokenItem] = currentYieldWalletManagers[walletModel.tokenItem]
                        ?? factory?.make(walletModel: walletModel)
                }
            }
            .sink { [weak self] result in
                self?._yieldWalletManagers.send(result)
            }
            .store(in: &bag)
    }
}

extension WalletModelFeature {
    var yieldModuleFactory: YieldModuleWalletManagerFactory? {
        if case .yieldModule(let factory) = self {
            return factory
        }
        return nil
    }
}
