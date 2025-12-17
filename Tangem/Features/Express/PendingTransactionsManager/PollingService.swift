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
        let (resultStream, resultContinuation) = AsyncStream<[Response]>.makeStream()
        let uuid = UUID()
        resultContinuations[uuid] = resultContinuation
        resultContinuation.onTermination = { [weak self] _ in
            runTask(isDetached: true) {
                await self?.unsubscribe(uuid: uuid)
            }
        }
        return resultStream
    }

    private let request: (RequestData) async -> ResponseData?
    private let shouldStopPolling: (ResponseData) -> Bool
    private let hasChanges: (ResponseData, ResponseData) -> Bool
    private let pollingInterval: TimeInterval

    private var resultContinuations: [UUID: AsyncStream<[Response]>.Continuation] = [:]
    private var latestResult: [Response] = []

    private var updateTask: Task<Void, Never>?

    init(
        request: @escaping (RequestData) async -> ResponseData?,
        shouldStopPolling: @escaping (ResponseData) -> Bool,
        hasChanges: @escaping (ResponseData, ResponseData) -> Bool,
        pollingInterval: TimeInterval
    ) {
        self.request = request
        self.shouldStopPolling = shouldStopPolling
        self.hasChanges = hasChanges
        self.pollingInterval = pollingInterval
    }

    deinit {
        // Calling `cancelTask()` produces a warning (error in the Swift 6 language mode)
        updateTask?.cancel()
        updateTask = nil

        resultContinuations.forEach { _, continuation in
            continuation.finish()
        }
    }

    func startPolling(requests: [RequestData], force: Bool) {
        guard updateTask == nil || force else {
            return
        }

        cancelTask()

        updateTask = runTask { [weak self] in
            await self?.poll(for: requests)
            await self?.cancelTask()
        }
    }

    func cancelTask() {
        updateTask?.cancel()
        updateTask = nil
    }

    private func poll(for requests: [RequestData]) async {
        if requests.isEmpty {
            return
        }

        // We have to remove result which is not contains in requests
        // Because we don't need it anymore
        latestResult = latestResult.filter { result in
            requests.contains(where: { $0.id == result.data.id })
        }
        sendValue(latestResult)

        while !Task.isCancelled {
            let responses = await withTaskGroup(of: Response?.self) { [weak self] taskGroup in
                for requestData in requests {
                    taskGroup.addTask {
                        await self?.getResponse(for: requestData)
                    }
                }

                var responses = [Response]()
                for await response in taskGroup {
                    if let response {
                        responses.append(response)
                    }
                }
                return responses
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
        resultContinuations.forEach { _, continuation in
            continuation.yield(value)
        }
    }

    private func unsubscribe(uuid: UUID) {
        resultContinuations.removeValue(forKey: uuid)
    }
}
