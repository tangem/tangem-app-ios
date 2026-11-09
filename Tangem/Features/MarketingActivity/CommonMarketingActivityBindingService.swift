//
//  CommonMarketingActivityBindingService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemNetworkUtils

final class CommonMarketingActivityBindingService {
    private let userWalletRepository: UserWalletRepository
    private let apiService: TangemApiService
    private let store: MarketingActivityBindingStore
    private let reachabilityProvider: NetworkReachabilityProvider

    private let receivedUids: AsyncStream<String>
    private let receivedUidsContinuation: AsyncStream<String>.Continuation
    private let storedUids = PassthroughSubject<Void, Never>()

    private var storingTask: Task<Void, Never>?
    private var deliveryTask: Task<Void, Never>?

    init(
        userWalletRepository: UserWalletRepository = InjectedValues[\.userWalletRepository],
        apiService: TangemApiService = InjectedValues[\.tangemApiService],
        store: MarketingActivityBindingStore = CommonMarketingActivityBindingStore(persistentStorage: InjectedValues[\.persistentStorage]),
        reachabilityProvider: NetworkReachabilityProvider = CommonNetworkReachabilityProvider()
    ) {
        self.userWalletRepository = userWalletRepository
        self.apiService = apiService
        self.store = store
        self.reachabilityProvider = reachabilityProvider

        (receivedUids, receivedUidsContinuation) = AsyncStream.makeStream()
    }

    deinit {
        storingTask?.cancel()
        deliveryTask?.cancel()
        receivedUidsContinuation.finish()
    }
}

// MARK: - MarketingActivityBindingService

extension CommonMarketingActivityBindingService: MarketingActivityBindingService {
    func initialize() {
        guard deliveryTask == nil else {
            return
        }

        bind()
    }

    func register(uid: String) {
        receivedUidsContinuation.yield(uid)
    }
}

// MARK: - Delivery

private extension CommonMarketingActivityBindingService {
    func bind() {
        storingTask = Task { [receivedUids, store, storedUids] in
            for await uid in receivedUids {
                await store.add(uid: uid)
                storedUids.send(())
            }
        }

        let deliveryTriggers = Publishers.CombineLatest3(
            reachabilityProvider.isReachablePublisher,
            hasWalletsPublisher(),
            storedUids.prepend(())
        )
        .filter { isReachable, hasWallets, _ in
            isReachable && hasWallets
        }

        deliveryTask = Task { [weak self] in
            for await _ in await deliveryTriggers.values_ {
                await self?.deliverPendingBindings()
            }
        }
    }

    func hasWalletsPublisher() -> AnyPublisher<Bool, Never> {
        userWalletRepository.eventProvider
            .map { _ in () }
            .merge(with: Just(()))
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { service, _ in
                !service.userWalletRepository.models.isEmpty
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func deliverPendingBindings() async {
        while let binding = await store.pending().first {
            let walletIds = await walletIds()

            guard !walletIds.isEmpty else {
                return
            }

            switch await deliver(binding, walletIds: walletIds) {
            case .delivered, .refused:
                await store.remove(id: binding.id)
            case .postponed:
                return
            }
        }
    }

    func deliver(_ binding: MarketingActivityBinding, walletIds: [String]) async -> DeliveryResult {
        let request = MarketingActivityDTO.BindWallets.Request(walletIds: walletIds)

        do {
            try await apiService.bindMarketingActivityWallets(uid: binding.uid, request: request)
            MarketingActivityLogger.info("Bound \(walletIds.count) wallet(s) to a marketing activity")
            return .delivered
        } catch where error.isRefusedByBackEnd {
            MarketingActivityLogger.warning("The backend refused a marketing activity binding")
            return .refused
        } catch {
            MarketingActivityLogger.warning("Couldn't bind wallets to a marketing activity, will retry later")
            return .postponed
        }
    }

    @MainActor
    func walletIds() -> [String] {
        userWalletRepository.models
            .map(\.userWalletId.stringValue)
            .unique()
    }
}

// MARK: - DeliveryResult

private extension CommonMarketingActivityBindingService {
    enum DeliveryResult {
        case delivered
        case refused
        case postponed
    }
}

// MARK: - Error

private extension Error {
    var isRefusedByBackEnd: Bool {
        guard let statusCode = asMoyaError?.response?.statusCode else {
            return false
        }

        let isRetryableClientError = [408, 429].contains(statusCode)
        return (400 ... 499).contains(statusCode) && !isRetryableClientError
    }
}
