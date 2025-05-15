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

    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> {
        return collectionsPublisherInternal
            .values()
            .eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<NFTManagerState, Never> {
        let aggregatedUpdatePublisher = [
            updatePublisher
                .eraseToAnyPublisher(),
            updateAssetsPublisher
                .mapToVoid()
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

    private lazy var collectionsPublisherInternal: some Publisher<Event<NFTPartialResult<[NFTCollection]>, Error>, Never> = {
        let aggregatedNetworkServicesPublisher = [
            updatePublisher
                .withLatestFrom(networkServicesPublisher)
                .map { ($0, true) } // An explicit update (due to a `update` call) always ignores the cache
                .eraseToAnyPublisher(),
            networkServicesPublisher
                .map { ($0, false) } // An update caused by changes in wallet models always uses the cache if it exists
                .eraseToAnyPublisher(),
        ].merge()

        let collectionsPublisher = aggregatedNetworkServicesPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { nftManager, input in
                let (networkServices, ignoreCache) = input

                return Just((nftManager, networkServices, ignoreCache))
                    .setFailureType(to: Error.self)
                    .asyncTryMap { nftManager, networkServices, ignoreCache in
                        return try await nftManager.updateInternal(networkServices: networkServices, ignoreCache: ignoreCache)
                    }
                    .materialize()
            }

        var assetsCache: [NFTCollection.ID: NFTPartialResult<[NFTAsset]>] = [:]

        let assetsPublisher = updateAssetsPublisher
            .withLatestFrom(networkServicesPublisher) { ($0, $1) }
            .compactMap { collectionIdentifier, networkServices -> (NFTCollection.ID, NFTNetworkService)? in
                let targetNetworkService = networkServices.first { walletModel, networkService in
                    return NFTWalletModelFinder.isWalletModel(walletModel, equalsTo: collectionIdentifier)
                }

                guard let networkService = targetNetworkService?.1 else {
                    return nil
                }

                return (collectionIdentifier, networkService)
            }
            .flatMapLatest { collectionIdentifier, networkService in
                return Just((collectionIdentifier, networkService))
                    .setFailureType(to: Error.self)
                    .asyncTryMap { collectionIdentifier, networkService in
                        let address = collectionIdentifier.ownerAddress
                        let assets = try await networkService.getAssets(address: address, collectionIdentifier: collectionIdentifier)

                        return (collectionIdentifier, assets)
                    }
                    .materialize()
            }

        let collectionsValuesPublisher = collectionsPublisher
            .values()
            .share()

        let collectionsErrorsPublisher = collectionsPublisher
            .failures()
            .mapToMaterializedFailure(outputType: NFTPartialResult<[NFTCollection]>.self)

        let assetsValuesPublisher = assetsPublisher
            .values()
            .prepend((NFTCollection.ID.dummy, NFTPartialResult(value: [])))
            .share()

        let enrichedCollectionsFromCollectionsPublisher = collectionsValuesPublisher
            .withLatestFrom(assetsValuesPublisher) { collections, assetsInput in
                let (collectionIdentifier, assetsLoadedResult) = assetsInput
                assetsCache[collectionIdentifier] = assetsLoadedResult

                return Self.enrichedCollections(collections, using: assetsCache)
            }
            .mapToMaterializedValue(failureType: Error.self)

        let enrichedCollectionsFromAssetsPublisher = assetsValuesPublisher
            .withLatestFrom(collectionsValuesPublisher) { assetsInput, collections in
                let (collectionIdentifier, assetsLoadedResult) = assetsInput
                assetsCache[collectionIdentifier] = assetsLoadedResult

                return Self.enrichedCollections(collections, using: assetsCache)
            }
            .mapToMaterializedValue(failureType: Error.self)

        return Publishers.Merge3(
            enrichedCollectionsFromCollectionsPublisher,
            enrichedCollectionsFromAssetsPublisher,
            collectionsErrorsPublisher
        )
        .share(replay: 1)
    }()

    private var updatePublisher: some Publisher<Void, Never> { updateSubject }
    private let updateSubject: some Subject<Void, Never> = PassthroughSubject()

    private var updateAssetsPublisher: some Publisher<NFTCollection.ID, Never> { updateAssetsSubject }
    private let updateAssetsSubject: some Subject<NFTCollection.ID, Never> = PassthroughSubject()

    private let walletModelsManager: WalletModelsManager
    private let updater = Updater()
    private var collectionsSubscription: AnyCancellable?

    init(
        walletModelsManager: WalletModelsManager
    ) {
        self.walletModelsManager = walletModelsManager
        bind()
    }

    func update() {
        updateSubject.send()
    }

    func updateAssets(inCollectionWithIdentifier collectionIdentifier: NFTCollection.ID) {
        updateAssetsSubject.send(collectionIdentifier)
    }

    private func bind() {
        // Not pure, but we still need some state in this manager
        collectionsSubscription = collectionsPublisherInternal
            .values()
            .map(\.value)
            .receiveOnMain()
            .assign(to: \.collections, on: self, ownership: .weak)
    }

    private func updateInternal(
        networkServices: [(any WalletModel, NFTNetworkService)],
        ignoreCache: Bool
    ) async throws -> NFTPartialResult<[NFTCollection]> {
        return try await updater.update(networkServices: networkServices, ignoreCache: ignoreCache)
    }

    private static func enrichedCollections(
        _ collections: NFTPartialResult<[NFTCollection]>,
        using assetsCache: [NFTCollection.ID: NFTPartialResult<[NFTAsset]>]
    ) -> NFTPartialResult<[NFTCollection]> {
        let enrichedCollections = collections.value.map { collection in
            guard let assets = assetsCache[collection.id] else {
                return collection
            }

            return collection.enriched(with: assets.value)
        }

        let assetsHadErrors = assetsCache.values.contains(where: { $0.hasErrors })
        return NFTPartialResult(
            value: enrichedCollections,
            hasErrors: collections.hasErrors || assetsHadErrors
        )
    }
}

// MARK: - Auxiliary types

private extension CommonNFTManager {
    actor Updater {
        typealias Task = _Concurrency.Task<NFTPartialResult<[NFTCollection]>, Error>

        enum UpdateTask {
            case inProgress(Task)
            case loaded(NFTPartialResult<[NFTCollection]>)
        }

        private var updateTasks: [WalletModelId: UpdateTask] = [:]

        nonisolated func update(
            networkServices: [(any WalletModel, NFTNetworkService)],
            ignoreCache: Bool
        ) async throws -> NFTPartialResult<[NFTCollection]> {
            return try await withThrowingTaskGroup(of: NFTPartialResult<[NFTCollection]>.self) { group in
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
                var mergedCollections: [NFTCollection] = []
                var mergedHadErrors = false

                for try await result in group {
                    mergedCollections += result.value
                    mergedHadErrors = mergedHadErrors || result.hasErrors
                }

                return NFTPartialResult(
                    value: mergedCollections,
                    hasErrors: mergedHadErrors
                )
            }
        }

        private func dispatchUpdate(
            walletModelId: WalletModelId,
            networkService: NFTNetworkService,
            address: String,
            ignoreCache: Bool
        ) async throws -> NFTPartialResult<[NFTCollection]> {
            if !ignoreCache, case .loaded(let loadedResult) = updateTasks[walletModelId] {
                return loadedResult
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

private extension Publisher {
    func mapToMaterializedValue<Failure>(failureType: Failure.Type) -> Publishers.Map<Self, Event<Self.Output, Failure>> {
        map { Event<Self.Output, Failure>.value($0) }
    }
}

private extension Publisher where Self.Output: Swift.Error {
    func mapToMaterializedFailure<Output>(outputType: Output.Type) -> Publishers.Map<Self, Event<Output, Self.Output>> {
        map { Event<Output, Self.Output>.failure($0) }
    }
}
