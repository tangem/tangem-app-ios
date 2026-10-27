//
//  CommonJointAccountPendingOperationPoller.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonJointAccountPendingOperationPoller {
    private let cryptoAccountId: String
    private let operationId: String
    private weak var delegate: JointAccountPendingOperationPollerLoader?

    private let regularPollingProcessor: RepeatedTaskProcessor
    private let frequentPollingProcessor: RepeatedTaskProcessor
    private let frequentUpdatesRequestsCount = OSAllocatedUnfairLock(initialState: 0)
    private let frequentUpdatesRequestsCountSubject = CurrentValueSubject<Int, Never>(0)
    private let knownETag = OSAllocatedUnfairLock<String?>(initialState: nil)

    private var pollingModeSubscription: Task<Void, Never>?

    init(
        cryptoAccountId: String,
        operationId: String,
        delegate: JointAccountPendingOperationPollerLoader,
        intervals: Intervals = .default
    ) {
        self.cryptoAccountId = cryptoAccountId
        self.operationId = operationId
        self.delegate = delegate
        regularPollingProcessor = RepeatedTaskProcessor(duration: intervals.regular)
        frequentPollingProcessor = RepeatedTaskProcessor(duration: intervals.frequent)

        bind()
    }

    deinit {
        pollingModeSubscription?.cancel()
    }
}

// MARK: - JointAccountPendingOperationPoller protocol conformance

extension CommonJointAccountPendingOperationPoller: JointAccountPendingOperationPoller {
    func requestFrequentUpdates() -> AnyCancellable? {
        changeFrequentUpdatesRequestsCount(by: 1)

        return AnyCancellable { [weak self] in
            self?.changeFrequentUpdatesRequestsCount(by: -1)
        }
    }
}

// MARK: - Private

private extension CommonJointAccountPendingOperationPoller {
    func changeFrequentUpdatesRequestsCount(by delta: Int) {
        frequentUpdatesRequestsCount.withLockUnchecked { count in
            count += delta
            frequentUpdatesRequestsCountSubject.send(count)
        }
    }

    func bind() {
        let publisher = frequentUpdatesRequestsCountSubject
            .map { $0 > 0 ? PollingMode.frequent : .regular }
            .removeDuplicates()

        pollingModeSubscription = Task { [weak self] in
            for await mode in publisher.values {
                await self?.updatePolling(mode: mode)
            }
        }
    }

    func updatePolling(mode: PollingMode) async {
        switch mode {
        case .regular:
            await frequentPollingProcessor.cancel()
            await startPolling(with: regularPollingProcessor, runsImmediately: false)
        case .frequent:
            await regularPollingProcessor.cancel()
            await startPolling(with: frequentPollingProcessor, runsImmediately: true)
        }
    }

    func startPolling(with processor: RepeatedTaskProcessor, runsImmediately: Bool) async {
        await processor.start(runsImmediately: runsImmediately) { [weak self] in
            await self?.poll()
        }
    }

    func poll() async {
        do {
            let eTag = knownETag.withLock { $0 }

            guard let result = try await delegate?.reloadPendingOperation(with: operationId, in: cryptoAccountId, knownETag: eTag) else {
                return
            }

            if case .modified(_, let newETag) = result {
                knownETag.withLock { $0 = newETag }
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }

            JointAccountsLogger.warning("Failed to read a joint operation anew, the next run is the retry: \(error)")
        }
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountPendingOperationPoller {
    struct Intervals {
        let regular: Duration
        let frequent: Duration

        static let `default` = Intervals(regular: .seconds(30), frequent: .seconds(2))
    }
}

private extension CommonJointAccountPendingOperationPoller {
    enum PollingMode {
        case regular
        case frequent
    }
}
