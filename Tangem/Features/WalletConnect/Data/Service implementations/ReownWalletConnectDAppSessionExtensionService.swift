//
//  ReownWalletConnectDAppSessionExtensionService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import ReownWalletKit

final class ReownWalletConnectDAppSessionExtensionService {
    private let walletKitClient: WalletKitClient
    private let socketConnectionStatusStorage: InMemorySocketConnectionStatusStorage
    private var socketConnectionStatusCancellable: AnyCancellable?

    init(walletKitClient: WalletKitClient) {
        self.walletKitClient = walletKitClient
        socketConnectionStatusStorage = InMemorySocketConnectionStatusStorage()

        subscribeToSocketConnectionStatus()
    }

    func extendSession(withTopic topic: String) async throws {
        try await socketConnectionHasBeenEstablished()
        try Task.checkCancellation()

        try await walletKitClient.extend(topic: topic)
    }

    // MARK: - Private methods

    private func socketConnectionHasBeenEstablished() async throws {
        try Task.checkCancellation()

        // Atomic check-and-store: if already connected, returns immediately.
        // Otherwise stores the continuation in a single actor call to avoid
        // a race where the socket connects between checking and storing.
        return await withCheckedContinuation { [socketConnectionStatusStorage] continuation in
            Task {
                await socketConnectionStatusStorage.storeIfNeeded(continuation: continuation)
            }
        }
    }

    private func subscribeToSocketConnectionStatus() {
        socketConnectionStatusCancellable = walletKitClient
            .socketConnectionStatusPublisher
            .sink { [weak self] socketConnectionStatus in
                Task {
                    await self?.handleSocketConnectionStatusUpdate(socketConnectionStatus)
                }
            }
    }

    private func handleSocketConnectionStatusUpdate(_ socketConnectionStatus: SocketConnectionStatus) async {
        let socketConnectionHasBeenEstablished = socketConnectionStatus == .connected

        await socketConnectionStatusStorage.update(socketConnectionHasBeenEstablished: socketConnectionHasBeenEstablished)

        guard socketConnectionHasBeenEstablished else {
            return
        }

        await socketConnectionStatusStorage.resumeSocketConnectionContinuations()
    }
}

extension ReownWalletConnectDAppSessionExtensionService {
    private actor InMemorySocketConnectionStatusStorage {
        private var socketConnectionContinuations = [CheckedContinuation<Void, Never>]()
        var socketConnectionHasBeenEstablished = false

        func update(socketConnectionHasBeenEstablished: Bool) {
            self.socketConnectionHasBeenEstablished = socketConnectionHasBeenEstablished
        }

        /// Atomically checks if the socket is already connected and either resumes the
        /// continuation immediately or stores it for later resumption.
        ///
        /// This prevents a race condition where the socket connects between separate
        /// check and store calls, leaving the continuation stored but never resumed.
        func storeIfNeeded(continuation: CheckedContinuation<Void, Never>) {
            if socketConnectionHasBeenEstablished {
                continuation.resume()
            } else {
                socketConnectionContinuations.append(continuation)
            }
        }

        func resumeSocketConnectionContinuations() {
            socketConnectionContinuations.forEach { $0.resume() }
            socketConnectionContinuations.removeAll()
        }
    }
}
