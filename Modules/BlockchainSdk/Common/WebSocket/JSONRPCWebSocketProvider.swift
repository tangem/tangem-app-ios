//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor JSONRPCWebSocketProvider {
    private let url: URL
    private let connection: WebSocketConnection

    // Internal
    private var requests: [Int: Continuation] = [:]
    private var receiveTask: Task<Void, Never>?
    private var counter: Int = 0

    init(url: URL, ping: WebSocketConnection.Ping, timeoutInterval: TimeInterval) {
        self.url = url
        connection = WebSocketConnection(url: url, ping: ping, timeout: timeoutInterval)
    }

    deinit {
        receiveTask?.cancel()
    }

    func send<Parameter: Encodable, Result: Decodable>(
        method: String,
        parameter: Parameter,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) async throws -> Result {
        counter += 1
        let request = JSONRPC.Request(id: counter, method: method, params: parameter)
        let message = try request.string(encoder: encoder)
        try await connection.send(.string(message))

        // setup handler for message
        setupReceiveTask()

        let data: Data = try await withCheckedThrowingContinuation { continuation in
            requests.updateValue(.init(continuation: continuation), forKey: request.id)
        }

        try Task.checkCancellation()

        // Remove the fulfilled `continuation` from cache
        requests.removeValue(forKey: request.id)
        let response = try decoder.decode(JSONRPC.Response<Result, JSONRPC.APIError>.self, from: data)

        assert(request.id == response.id, "The response contains wrong id")

        switch response.result {
        case .success: BSDKLogger.info(self, "Return success for id \(response.id as Any)")
        case .failure: BSDKLogger.info(self, "Return failure for id \(response.id as Any)")
        }

        return try response.result.get()
    }

    func cancel() async {
        receiveTask?.cancel()

        for key in requests.keys {
            await requests[key]?.cancel()
            requests.removeValue(forKey: key)
        }
    }
}

// MARK: - Private

private extension JSONRPCWebSocketProvider {
    func setupReceiveTask() {
        // `self` must not be held across the unbounded `receive()` await — the stored task
        // would retain the provider (and the whole socket stack) until the connection errors out
        receiveTask = Task { [weak self, connection] in
            do {
                let data = try await connection.receive()

                await self?.proceedReceive(data: data)

                // Handle next message
                await self?.setupReceiveTask()
            } catch {
                guard let self else { return }

                BSDKLogger.error(self, "ReceiveTask catch error", error: error)
                await cancel()
            }
        }
    }

    func proceedReceive(data: Data) async {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let id = json?["id"] as? Int else {
                BSDKLogger.error(self, error: "Received json: \(String(describing: json)) has wrong id")
                return
            }

            if let continuation = requests[id] {
                await continuation.resume(returning: data)
            } else if id == WebSocketConnection.Ping.Constants.id {
                BSDKLogger.info(self, "The ping message response received: \(String(describing: json))")
            } else {
                BSDKLogger.warning(self, "Received json: \(String(describing: json)) is not handled")
            }
        } catch {
            BSDKLogger.error(self, "Receive catch parse error", error: error)
        }
    }
}

// MARK: - HostProvider

extension JSONRPCWebSocketProvider: HostProvider {
    nonisolated var host: String { url.hostOrUnknown }
}

// MARK: - CustomStringConvertible

extension JSONRPCWebSocketProvider: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self)
    }
}

private actor Continuation {
    private let continuation: CheckedContinuation<Data, Error>
    private var isResumed: Bool = false

    init(continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func resume(returning data: Data) {
        guard !isResumed else { return }

        continuation.resume(returning: data)
        isResumed = true
    }

    func resume(throwing error: any Error) {
        guard !isResumed else { return }

        continuation.resume(throwing: error)
        isResumed = true
    }

    func cancel() {
        guard !isResumed else { return }

        continuation.resume(throwing: CancellationError())
        isResumed = true
    }
}
