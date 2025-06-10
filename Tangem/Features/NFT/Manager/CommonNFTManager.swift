//
//  CommonNFTManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import TangemNFT

// [REDACTED_TODO_COMMENT]
final class CommonNFTManager: NFTManager {
    private(set) var collections: [NFTCollection] = []

    var collectionsPublisher: AnyPublisher<[NFTCollection], Never> {
        return collectionsPublisherInternal
            .values()
            .eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<NFTManagerState, Never> {
        let aggregatedUpdatePublisher = [
            updatePublisher
                .eraseToAnyPublisher(),
            networkServicesPublisher
                .mapToVoid()
                .eraseToAnyPublisher(),
        ].merge()

        let statePublishers = [
            aggregatedUpdatePublisher
                .mapToValue(NFTManagerState.loading)
                .eraseToAnyPublisher(),
            collectionsPublisherInternal
                .values()
                .map(NFTManagerState.loaded)
                .eraseToAnyPublisher(),
            collectionsPublisherInternal
                .failures()
                .map(NFTManagerState.failedToLoad)
                .eraseToAnyPublisher(),
        ]

        return statePublishers
            .merge()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private lazy var networkServicesPublisher: some Publisher<[(any WalletModel, NFTNetworkService)], Never> = {
        let walletModelsPublisher = walletModelsManager
            .walletModelsPublisher
            .removeDuplicates()

        return walletModelsPublisher
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
            .map { features -> [(any WalletModel, NFTNetworkService)] in
                return features.reduce(into: []) { result, element in
                    let (walletModel, features) = element
                    for feature in features {
                        if let nftNetworkService = feature.nftNetworkService {
                            result.append((walletModel, nftNetworkService))
                        }
                    }
                }
            }
            .share(replay: 1)
    }()

    private lazy var collectionsPublisherInternal: some Publisher<Event<[NFTCollection], Error>, Never> = {
        let aggregatedNetworkServicesPublisher = [
            updatePublisher
                .withLatestFrom(networkServicesPublisher)
                .map { ($0, true) } // An explicit update (due to a `update` call) always ignores the cache
                .eraseToAnyPublisher(),
            networkServicesPublisher
                .map { ($0, false) } // An update caused by changes in wallet models always uses the cache if it exists
                .eraseToAnyPublisher(),
        ].merge()

        return aggregatedNetworkServicesPublisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .asyncTryMap { nftManager, input in
                let (networkServices, ignoreCache) = input
                return try await nftManager.updateInternal(networkServices: networkServices, ignoreCache: ignoreCache)
            }
            .materialize()
            .share(replay: 1)
            .eraseToAnyPublisher()
    }()

    private var updatePublisher: some Publisher<Void, Never> { updateSubject }
    private let updateSubject: some Subject<Void, Never> = PassthroughSubject()
    private let walletModelsManager: WalletModelsManager
    private let updater = Updater()
    private var bag: Set<AnyCancellable> = []

    init(
        walletModelsManager: WalletModelsManager
    ) {
        self.walletModelsManager = walletModelsManager
        bind()
    }

    func update() {
        updateSubject.send()
    }

    private func bind() {
        // Not pure, but we still need some state in this manager
        collectionsPublisherInternal
            .values()
            .receive(on: DispatchQueue.main)
            .assign(to: \.collections, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func updateInternal(
        networkServices: [(any WalletModel, NFTNetworkService)],
        ignoreCache: Bool
    ) async throws -> [NFTCollection] {
        return try await updater.update(networkServices: networkServices, ignoreCache: ignoreCache)
    }
}

// MARK: - Auxiliary types

private extension CommonNFTManager {
    actor Updater {
        typealias Task = _Concurrency.Task<[NFTCollection], Error>

        enum UpdateTask {
            case inProgress(Task)
            case loaded([NFTCollection])
        }

        private var updateTasks: [WalletModelId: UpdateTask] = [:]

        nonisolated func update(
            networkServices: [(any WalletModel, NFTNetworkService)],
            ignoreCache: Bool
        ) async throws -> [NFTCollection] {
            return try await withThrowingTaskGroup(of: [NFTCollection].self) { group in
                for (walletModel, networkService) in networkServices {
                    for address in walletModel.addresses {
                        group.addTask {
                            try await self.dispatchUpdate(
                                walletModelId: walletModel.id,
                                networkService: networkService,
                                address: address.value,
                                ignoreCache: ignoreCache
                            )
                        }
                    }
                }

                // Can't use `group.reduce` here due to https://forums.swift.org/t/60271
                var collections: [NFTCollection] = []
                for try await nftCollection in group {
                    collections += nftCollection
                }

                return collections
            }
        }

        private func dispatchUpdate(
            walletModelId: WalletModelId,
            networkService: NFTNetworkService,
            address: String,
            ignoreCache: Bool
        ) async throws -> [NFTCollection] {
            if !ignoreCache, case .loaded(let collections) = updateTasks[walletModelId] {
                return collections
            }

            if case .inProgress(let task) = updateTasks[walletModelId] {
                return try await task.value
            }

            let task = Task {
                try await networkService.getCollections(address: address)
            }

            updateTasks[walletModelId] = .inProgress(task)

            do {
                let value = try await task.value
                updateTasks[walletModelId] = .loaded(value)
                return value
            } catch {
                updateTasks[walletModelId] = nil
                throw error
            }
        }
    }
}

// MARK: - Convenience extensions

private extension WalletModelFeature {
    var nftNetworkService: NFTNetworkService? {
        if case .nft(let networkService) = self {
            return networkService
        }

        return nil
    }
}
