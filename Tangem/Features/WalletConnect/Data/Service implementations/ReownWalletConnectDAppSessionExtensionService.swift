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
        if await socketConnectionStatusStorage.socketConnectionHasBeenEstablished {
            return
        }

        try Task.checkCancellation()

        return await withCheckedContinuation { [socketConnectionStatusStorage] continuation in
            Task {
                await socketConnectionStatusStorage.store(continuation: continuation)
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

        func store(continuation: CheckedContinuation<Void, Never>) {
            socketConnectionContinuations.append(continuation)
        }

        func resumeSocketConnectionContinuations() {
            socketConnectionContinuations.forEach { $0.resume() }
            socketConnectionContinuations.removeAll()
        }
    }
}
