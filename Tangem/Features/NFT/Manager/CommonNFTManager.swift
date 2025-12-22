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
    private let analytics: NFTAnalytics.Error

    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> {
        return collectionsPublisherRemote
            .values()
            .merge(with: collectionsPublisherCached)
            .eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<NFTManagerState, Never> {
        return Publishers.Merge5(
            updatePublisher.mapToValue(NFTManagerState.loading),
            updateAssetsPublisher.mapToValue(NFTManagerState.loading),
            // There is no point in caching empty collections
            collectionsPublisherCached.filter { !$0.value.isEmpty }.map(NFTManagerState.success),
            collectionsPublisherRemote.values().map(NFTManagerState.success),
            collectionsPublisherRemote.failures().map(NFTManagerState.failure),
        )
        .removeDuplicates(by: Self.equivalentNFTManagerStatePredicate)
        .eraseToAnyPublisher()
    }

    private lazy var networkServicesPublisher: some Publisher<[(any WalletModel, NFTNetworkService)], Never> = {
        let walletModelsPublisher = walletModelsPublisher
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

    private lazy var collectionsPublisherCached: some Publisher<NFTPartialResult<[NFTCollection]>, Never> = Publishers.Merge(
        updatePublisher.filter(\.isCacheEnabled).mapToVoid(),
        networkServicesPublisher.mapToVoid(),
    )
    .withWeakCaptureOf(self)
    .map { nftManager, _ in
        let collections = nftManager.cache.getCollections()
        return .init(value: collections)
    }
    .share(replay: 1)

    private lazy var collectionsPublisherRemote: some Publisher<Event<NFTPartialResult<[NFTCollection]>, Error>, Never> = {
        let collectionsPublisher = updatePublisher
            .filter(\.isCacheDisabled)
            .withLatestFrom(networkServicesPublisher)
            .withWeakCaptureOf(self)
            .flatMapLatest { nftManager, networkServices in
                return Just((nftManager, networkServices))
                    .setFailureType(to: Error.self)
                    .asyncTryMap { nftManager, networkServices in
                        // An explicit update (due to a `update` call) always ignores the cache
                        return try await nftManager.updateInternal(networkServices: networkServices, ignoreCache: true)
                    }
                    .materialize()
            }

        var assetsCache: [NFTCollection.ID: NFTPartialResult<[NFTAsset]>] = [:]

        let assetsPublisher = updateAssetsPublisher
            .withLatestFrom(networkServicesPublisher) { ($0, $1) }
            .compactMap { collection, networkServices -> (NFTCollection, NFTNetworkService)? in
                let targetNetworkService = networkServices.first { walletModel, networkService in
                    return NFTWalletModelFinder.isWalletModel(walletModel, equalsTo: collection.id)
                }

                guard let networkService = targetNetworkService?.1 else {
                    return nil
                }

                return (collection, networkService)
            }
            .flatMapLatest { collection, networkService in
                let emptyAssets = Just((collection, NFTPartialResult<[NFTAsset]>(value: [])))
                    .setFailureType(to: Error.self)

                let enrichedAssets = Just((collection, networkService))
                    .setFailureType(to: Error.self)
                    .asyncTryMap { collection, networkService in
                        let assets = try await Self.fetchAssets(in: collection, using: networkService)
                        let updatedAssets = await Self.updateAssets(assets, using: networkService)

                        return (collection, updatedAssets)
                    }

                // Append is used to ensure that each update cycle starts with loading
                return emptyAssets
                    .append(enrichedAssets)
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
            .prepend((NFTCollection.dummy, []))
            .share()

        let enrichedCollectionsFromCollectionsPublisher = collectionsValuesPublisher
            .withLatestFrom(assetsValuesPublisher) { collections, assetsInput in
                let (collection, assetsLoadedResult) = assetsInput
                assetsCache[collection.id] = assetsLoadedResult

                return Self.enrichedCollections(collections, using: assetsCache)
            }
            .mapToMaterializedValue(failureType: Error.self)

        let enrichedCollectionsFromAssetsPublisher = assetsValuesPublisher
            .withLatestFrom(collectionsValuesPublisher) { assetsInput, collections in
                let (collection, assetsLoadedResult) = assetsInput
                assetsCache[collection.id] = assetsLoadedResult

                return Self.enrichedCollections(collections, using: assetsCache)
            }
            .mapToMaterializedValue(failureType: Error.self)

        return Publishers.Merge3(
            enrichedCollectionsFromCollectionsPublisher,
            enrichedCollectionsFromAssetsPublisher,
            collectionsErrorsPublisher
        )
        .share() // No replay is needed here, since the remote collections must always be fetched explicitly
    }()

    private var updatePublisher: some Publisher<NFTCachePolicy, Never> { updateSubject }
    private let updateSubject: some Subject<NFTCachePolicy, Never> = PassthroughSubject()

    private var updateAssetsPublisher: some Publisher<NFTCollection, Never> { updateAssetsSubject }
    private let updateAssetsSubject: some Subject<NFTCollection, Never> = PassthroughSubject()

    private let walletModelsPublisher: AnyPublisher<[any WalletModel], Never>
    private let cache: NFTCache
    private let cacheDelegate: NFTCacheDelegate
    private let updater: Updater
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        walletModelsPublisher: AnyPublisher<[any WalletModel], Never>,
        provideWalletModels: @escaping () -> [any WalletModel],
        analytics: NFTAnalytics.Error
    ) {
        self.analytics = analytics
        self.walletModelsPublisher = walletModelsPublisher

        let cache = NFTCache(userWalletId: userWalletId)
        let cacheDelegate = CommonNFTCacheDelegate(provideWalletModels: provideWalletModels)
        cache.delegate = cacheDelegate
        self.cache = cache
        self.cacheDelegate = cacheDelegate

        updater = Updater(analytics: analytics)

        bind()
    }

    func update(cachePolicy: NFTCachePolicy) {
        updateSubject.send(cachePolicy)
    }

    func updateAssets(in collection: NFTCollection) {
        updateAssetsSubject.send(collection)
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
            guard let assetsResult = assetsCache[collection.id] else {
                return collection
            }

            return collection.enriched(with: assetsResult)
        }

        return NFTPartialResult(
            value: enrichedCollections,
            errors: collections.errors
        )
    }

    private static func fetchAssets(
        in collection: NFTCollection,
        using networkService: NFTNetworkService,
    ) async throws -> NFTPartialResult<[NFTAsset]> {
        return await networkService.getAssets(
            address: collection.id.ownerAddress,
            in: collection
        )
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

            return NFTPartialResult(value: updatedAssets, errors: assets.errors)
        }
    }
}

// MARK: - Auxiliary types

private extension CommonNFTManager {
    actor Updater {
        typealias CollectionsTask = _Concurrency.Task<NFTPartialResult<[NFTCollection]>, Error>

        enum UpdateTask {
            case inProgress(CollectionsTask)
            case loaded(NFTPartialResult<[NFTCollection]>)
        }

        private var updateTasks: [WalletModelId: UpdateTask] = [:]
        private let analytics: NFTAnalytics.Error

        init(analytics: NFTAnalytics.Error) {
            self.analytics = analytics
        }

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
                var mergedErrors: [NFTErrorDescriptor] = []

                for try await result in group {
                    mergedCollections += result.value
                    mergedErrors += result.errors
                }

                logErrors(mergedErrors)

                // The sorting logic here has nothing to do with the order of collections in the UI,
                // it's only used to ensure a stable order of NFT collections so that `removeDuplicates` works correctly
                return NFTPartialResult(
                    value: mergedCollections.sorted(by: \.stableSortKey),
                    errors: mergedErrors.sorted(by: \.code)
                )
            }
        }

        nonisolated func logErrors(_ errors: [NFTErrorDescriptor]) {
            Task.detached {
                await withTaskGroup(of: Void.self) { group in
                    for error in errors {
                        group.addTask {
                            await self.analytics.logError("\(error.code)", error.description)
                        }
                    }
                }
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

            let task = CollectionsTask {
                await networkService.getCollections(address: address)
            }

            updateTasks[walletModelId] = .inProgress(task)

            do {
                let value = try await task.value
                updateTasks[walletModelId] = .loaded(value)
                return value
            } catch {
                updateTasks[walletModelId] = nil
                analytics.logError("\(error.universalErrorCode)", error.localizedDescription)
                throw error
            }
        }
    }

    private static func equivalentNFTManagerStatePredicate(_ lhs: NFTManagerState, rhs: NFTManagerState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            true
        case (.success(let lhsValue), .success(let rhsValue)):
            lhsValue == rhsValue
        case (.failure(let lhsError), .failure(let rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
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

private extension NFTCollection {
    var stableSortKey: String {
        id.collectionIdentifier + id.ownerAddress + id.chain.id
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
