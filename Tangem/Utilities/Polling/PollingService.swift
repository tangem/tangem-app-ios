//
//  PollingService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor PollingService<RequestData: Identifiable, ResponseData: Identifiable>: Sendable where RequestData.ID == ResponseData.ID {
    struct Response {
        let data: ResponseData
        let hasChanges: Bool
    }

    var resultStream: AsyncStream<[Response]> {
        AsyncStream<[Response]>.multicast(
            with: self,
            onSubscribe: { poller, id, continuation in
                poller.subscribers.subscribe(id: id, continuation: continuation)
            },
            onUnsubscribe: { poller, id in
                poller.subscribers.unsubscribe(id: id)
            }
        )
    }

    private let request: (RequestData) async -> ResponseData?
    private let shouldStopPolling: (ResponseData) -> Bool
    private let hasChanges: (ResponseData, ResponseData) -> Bool
    private let pollingInterval: TimeInterval
    private let maxConcurrentRequests: Int?

    private var subscribers = AsyncStream<[Response]>.MulticastSubscribers<UUID>()
    private var latestResult: [Response] = []

    private var updateTask: Task<Void, Never>?

    init(
        request: @escaping (RequestData) async -> ResponseData?,
        shouldStopPolling: @escaping (ResponseData) -> Bool,
        hasChanges: @escaping (ResponseData, ResponseData) -> Bool,
        pollingInterval: TimeInterval,
        maxConcurrentRequests: Int? = nil
    ) {
        if let maxConcurrentRequests {
            precondition(maxConcurrentRequests > 0, "maxConcurrentRequests must be greater than 0")
        }

        self.request = request
        self.shouldStopPolling = shouldStopPolling
        self.hasChanges = hasChanges
        self.pollingInterval = pollingInterval
        self.maxConcurrentRequests = maxConcurrentRequests
    }

    deinit {
        // Calling `cancelTask()` produces a warning (error in the Swift 6 language mode)
        updateTask?.cancel()
        updateTask = nil
    }

    func startPolling(requests: [RequestData], force: Bool) {
        guard updateTask == nil || force else {
            return
        }

        cancelTask()

        updateTask = runTask { [weak self] in
            guard let self else { return }
            let chunkSize = maxConcurrentRequests ?? requests.count
            await pollChunked(for: requests, chunkSize: max(chunkSize, 1))
            if !Task.isCancelled {
                await clearUpdateTask()
            }
        }
    }

    func cancelTask() {
        updateTask?.cancel()
        updateTask = nil
    }

    private func clearUpdateTask() {
        updateTask = nil
    }

    private func pollChunked(for requests: [RequestData], chunkSize: Int) async {
        guard !requests.isEmpty else { return }

        // Remove results which are not contained in requests
        latestResult = latestResult.filter { result in
            requests.contains(where: { $0.id == result.data.id })
        }
        sendValue(latestResult)

        while !Task.isCancelled {
            var responses = [Response]()

            for chunkStart in stride(from: requests.startIndex, to: requests.endIndex, by: chunkSize) {
                let chunk = requests[chunkStart ..< min(chunkStart + chunkSize, requests.endIndex)]
                guard !Task.isCancelled else { break }

                let chunkResponses = await withTaskGroup(of: Response?.self) { taskGroup in
                    for requestData in chunk {
                        taskGroup.addTask { [weak self] in
                            await self?.getResponse(for: requestData)
                        }
                    }

                    var results = [Response]()
                    for await response in taskGroup {
                        if let response {
                            results.append(response)
                        }
                    }
                    return results
                }

                responses.append(contentsOf: chunkResponses)
            }

            latestResult = responses
            sendValue(responses)
            try? await Task.sleep(for: .seconds(pollingInterval))
        }
    }

    private func getResponse(for requestData: RequestData) async -> Response? {
        let previousResponse = latestResult
            .first { $0.data.id == requestData.id }

        if let previousResponse, shouldStopPolling(previousResponse.data) {
            return Response(data: previousResponse.data, hasChanges: false)
        }

        guard let responseData = await request(requestData) else {
            return previousResponse.map {
                Response(data: $0.data, hasChanges: false)
            }
        }

        if let previousResponse {
            return Response(
                data: responseData,
                hasChanges: hasChanges(previousResponse.data, responseData)
            )
        }

        return Response(data: responseData, hasChanges: true)
    }

    private func sendValue(_ value: [Response]) {
        subscribers.yield(value)
    }
}
