//
//  MCPUserWalletImageRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class UIKit.UIImage
import struct TangemFoundation.UserWalletId

actor MCPUserWalletImageRepository {
    private let maxConcurrentFetches: UInt
    private let fetchImage: (UserWalletId) async -> UIImage

    private var cache: [UserWalletId: UIImage]
    private var tasks: [UserWalletId: Task<UIImage, Never>]

    private var inFlightTasksCount: Int
    private var waiters: [CheckedContinuation<Void, Never>]

    init(maxConcurrentFetches: UInt, fetchImage: @escaping @Sendable (UserWalletId) async -> UIImage) {
        self.maxConcurrentFetches = maxConcurrentFetches
        self.fetchImage = fetchImage

        cache = [UserWalletId: UIImage]()
        tasks = [UserWalletId: Task<UIImage, Never>]()

        inFlightTasksCount = 0
        waiters = [CheckedContinuation<Void, Never>]()
    }

    func retrieve(by id: UserWalletId) async -> UIImage {
        if let cachedImage = cache[id] {
            return cachedImage
        }

        if let enqueuedTask = tasks[id] {
            return await enqueuedTask.value
        }

        let newFetchTask = Task { await enqueueNewFetchTask(for: id) }
        tasks[id] = newFetchTask
        return await newFetchTask.value
    }

    private func enqueueNewFetchTask(for id: UserWalletId) async -> UIImage {
        await acquireFetchSlot()
        let image = await fetchImage(id)
        releaseFetchSlot()

        cache[id] = image
        tasks[id] = nil

        return image
    }

    private func acquireFetchSlot() async {
        let canStartNewTaskImmediately = inFlightTasksCount < maxConcurrentFetches

        if canStartNewTaskImmediately {
            inFlightTasksCount += 1
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private func releaseFetchSlot() {
        guard !waiters.isEmpty else {
            inFlightTasksCount -= 1
            return
        }

        waiters.removeFirst().resume()
    }
}
