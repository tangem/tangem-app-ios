//
//  WebSocket.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

class WebSocket {
    let url: URL

    var request: URLRequest
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?

    private let pingInterval: TimeInterval = 30
    private let timeoutInterval: TimeInterval = 20

    private(set) var isConnected = false

    private lazy var session: URLSession = {
        let delegate = WebSocketConnectionDelegate(eventHandler: { [weak self] event in
            self?.handleEvent(event)
        })
        let configuration = URLSessionConfiguration.default
        configuration.shouldUseExtendedBackgroundIdleMode = true
        configuration.waitsForConnectivity = true

        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }()

    private var bgTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    // needed to keep connection alive
    private var pingTimer: Timer?
    private var task: URLSessionWebSocketTask?

    private var bag = Set<AnyCancellable>()

    init(
        url: URL,
        onConnect: (() -> Void)? = nil,
        onDisconnect: ((Error?) -> Void)? = nil,
        onText: ((String) -> Void)? = nil
    ) {
        self.url = url
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onText = onText

        request = URLRequest(url: url, timeoutInterval: timeoutInterval)

        // On actual iOS devices, request some additional background execution time to the OS
        // each time that the app moves to background. This allows us to continue running for
        // around 30 secs in the background instead of having the socket killed instantly, which
        // solves the issue of connecting a wallet and a dApp both on the same device.
        // See https://github.com/WalletConnect/WalletConnectSwift/pull/81#issuecomment-1175931673

        NotificationCenter.default
            .publisher(for: UIScene.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.requestBackgroundExecutionTime()
            })
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIScene.didActivateNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.endBackgroundTask()
            })
            .store(in: &bag)
    }

    deinit {
        session.invalidateAndCancel()
        pingTimer?.invalidate()
    }

    func connect() {
        disconnect()
        task = session.webSocketTask(with: request)
        task?.resume()
        receive()
    }

    func disconnect() {
        pingTimer?.invalidate()
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    func write(string text: String, completion: (() -> Void)?) {
        guard isConnected else { return }

        task?.send(.string(text)) { [weak self] error in
            if let error = error {
                self?.handleEvent(.connnectionError(error))
            } else {
                completion?()
                self?.handleEvent(.messageSent(text))
            }
        }
    }

    private func receive() {
        guard let task = task else { return }

        task.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self?.handleEvent(.messageReceived(text))
                }
                self?.receive()
            case .failure(let error):
                self?.handleEvent(.connnectionError(error))
            }
        }
    }

    private func sendPing() {
        guard isConnected else { return }

        task?.sendPing(pongReceiveHandler: { [weak self] error in
            if let error {
                self?.handleEvent(.connnectionError(error))
                return
            }

            self?.handleEvent(.pongReceived)
        })
        handleEvent(.pingSent)
    }

    private func handleEvent(_ event: WebSocketEvent) {
        switch event {
        case .connected:
            isConnected = true
            DispatchQueue.main.async {
                self.pingTimer = Timer.scheduledTimer(
                    withTimeInterval: self.pingInterval,
                    repeats: true
                ) { [weak self] _ in
                    self?.sendPing()
                }
            }
            AppLog.shared.debug("[WebSocket] connected")
            onConnect?()
        case .disconnected(let closeCode):
            guard isConnected else { break }

            isConnected = false
            pingTimer?.invalidate()

            var error: Error?
            switch closeCode {
            case .normalClosure:
                AppLog.shared.debug("[WebSocket] 💥💥💥 disconnected (normal closure)")
            case .abnormalClosure, .goingAway:
                AppLog.shared.debug("[WebSocket] 💥💥💥 disconnected (peer disconnected)")
                error = WebSocketError.peerDisconnected
            default:
                AppLog.shared.debug("[WebSocket] 💥💥💥 disconnected (\(closeCode)")
                error = WebSocketError.closedUnexpectedly
            }
            disconnectOnMainThread(with: error)
        case .messageReceived(let text):
            onText?(text)
        case .messageSent(let text):
            AppLog.shared.debug("[WebSocket] ==> \(text)")
        case .pingSent:
            AppLog.shared.debug("[WebSocket] ==> ping")
        case .pongReceived:
            AppLog.shared.debug("[WebSocket] <== pong")
        case .connnectionError(let error):
            AppLog.shared.debug("[WebSocket] Connection error: \(error.localizedDescription)")
            disconnectOnMainThread(with: error)
        }
    }

    private func requestBackgroundExecutionTime() {
        if bgTaskIdentifier != .invalid {
            endBackgroundTask()
        }

        bgTaskIdentifier = UIApplication.shared.beginBackgroundTask(
            withName: "WebSocketConnection-bgTime"
        ) { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard bgTaskIdentifier != .invalid else { return }

        UIApplication.shared.endBackgroundTask(bgTaskIdentifier)
        bgTaskIdentifier = .invalid
    }

    private func disconnectOnMainThread(with error: Error?) {
        if Thread.isMainThread {
            onDisconnect?(error)
            return
        }

        DispatchQueue.main.async {
            self.onDisconnect?(error)
        }
    }
}
