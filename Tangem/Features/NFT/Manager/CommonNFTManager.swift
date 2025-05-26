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

final class CommonNFTManager: NFTManager {
    private(set) var collections: [NFTCollection] = []

    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> {
        return collectionsPublisherRemote
            .values()
            .merge(with: collectionsPublisherCached)
            .eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<NFTManagerState, Never> {
        let aggregatedUpdatePublisher = [
            updatePublisher
                .mapToVoid()
                .eraseToAnyPublisher(),
            updateAssetsPublisher
                .mapToVoid()
                .eraseToAnyPublisher(),
            networkServicesPublisher
                .mapToVoid()
                .eraseToAnyPublisher(),
        ].merge()

        let statePublishers = [
            collectionsPublisherCached
                .map(NFTManagerState.loaded)
                .eraseToAnyPublisher(),
            collectionsPublisherRemote
                .values()
                .map(NFTManagerState.loaded)
                .eraseToAnyPublisher(),
            collectionsPublisherRemote
                .failures()
                .map(NFTManagerState.failedToLoad)
                .eraseToAnyPublisher(),
        ].merge()

        // Append is used to ensure that each update cycle starts with loading
        return aggregatedUpdatePublisher
            .flatMap { _ in
                Just(NFTManagerState.loading)
                    .append(statePublishers)
            }
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

    private lazy var collectionsPublisherCached: some Publisher<NFTPartialResult<[NFTCollection]>, Never> = updatePublisher
        .filter(\.isCacheEnabled)
        .mapToVoid()
        .merge(with: networkServicesPublisher.mapToVoid())
        .withWeakCaptureOf(self)
        .map { nftManager, _ in
            let collections = nftManager.cache.getCollections()
            return .init(value: collections)
        }
        .share(replay: 1)

    private lazy var collectionsPublisherRemote: some Publisher<Event<NFTPartialResult<[NFTCollection]>, Error>, Never> = {
        let aggregatedNetworkServicesPublisher = [
            updatePublisher
                .filter(\.isCacheDisabled)
                .withLatestFrom(networkServicesPublisher)
                .map { ($0, true) } // An explicit update (due to a `update` call) always ignores the cache
                .eraseToAnyPublisher(),
            networkServicesPublisher
                // Change in wallet models and/or user wallets can't request an update until
                // an explicit update (by calling `update(cachePolicy:)`) has been done at least once
                .drop(untilOutputFrom: updatePublisher.filter(\.isCacheDisabled))
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
                        let assets = try await Self.fetchAssets(inCollectionWithIdentifier: collectionIdentifier, using: networkService)
                        let updatedAssets = await Self.updateAssets(assets, using: networkService)

                        return (collectionIdentifier, updatedAssets)
                    }
                    .materialize()
            }

        let collectionsValuesPublisher = collectionsPublisher
            .values()
            .share()

        let collectionsErrorsPublisher = collectionsPublisher
            .failures()
            .mapToMaterializedFailure(outputType: NFTPartialResult<[NFTCollection]>.self)

        // Prepend is used to ensure that `assetsValuesPublisher` won't prevent the merged publisher from emitting values
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

    private var updatePublisher: some Publisher<NFTCachePolicy, Never> { updateSubject }
    private let updateSubject: some Subject<NFTCachePolicy, Never> = PassthroughSubject()

    private var updateAssetsPublisher: some Publisher<NFTCollection.ID, Never> { updateAssetsSubject }
    private let updateAssetsSubject: some Subject<NFTCollection.ID, Never> = PassthroughSubject()

    private let walletModelsManager: WalletModelsManager
    private let cache: NFTCache
    private let cacheDelegate: NFTCacheDelegate
    private let updater = Updater()

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager
    ) {
        self.walletModelsManager = walletModelsManager
        let cache = NFTCache(cacheFileName: .cachedNFTAssets(userWalletId: userWalletId))
        let cacheDelegate = CommonNFTCacheDelegate(walletModelsManager: walletModelsManager)
        cache.delegate = cacheDelegate
        self.cache = cache
        self.cacheDelegate = cacheDelegate
        bind()
    }

    func update(cachePolicy: NFTCachePolicy) {
        updateSubject.send(cachePolicy)
    }

    func updateAssets(inCollectionWithIdentifier collectionIdentifier: NFTCollection.ID) {
        updateAssetsSubject.send(collectionIdentifier)
    }

    private func bind() {
        // Not pure, but we still need some state in this manager
        collectionsPublisherRemote
            .values()
            .map(\.value)
            .withWeakCaptureOf(self)
            .sink { nftManager, collections in
                nftManager.cache.save(collections)
            }
            .store(in: &bag)

        collectionsPublisher
            .map(\.value)
            .receiveOnMain()
            .assign(to: \.collections, on: self, ownership: .weak)
            .store(in: &bag)
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

    private static func fetchAssets(
        inCollectionWithIdentifier collectionIdentifier: NFTCollection.ID,
        using networkService: NFTNetworkService
    ) async throws -> NFTPartialResult<[NFTAsset]> {
        return try await networkService.getAssets(address: collectionIdentifier.ownerAddress, collectionIdentifier: collectionIdentifier)
    }

    private static func updateAssets(
        _ assets: NFTPartialResult<[NFTAsset]>,
        using networkService: NFTNetworkService
    ) async -> NFTPartialResult<[NFTAsset]> {
        return await withTaskGroup(of: NFTAsset.self) { group in
            for asset in assets.value {
                group.addTask {
                    // Errors are intentionally ignored since the last sale price is always optional
                    let salePrice = try? await networkService.getSalePrice(assetIdentifier: asset.id)
                    return asset.enriched(with: salePrice)
                }
            }

            // Can't use `group.reduce` here due to https://forums.swift.org/t/60271
            var updatedAssets: [NFTAsset] = []
            for await asset in group {
                updatedAssets.append(asset)
            }

            return NFTPartialResult(value: updatedAssets, hasErrors: assets.hasErrors)
        }
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
