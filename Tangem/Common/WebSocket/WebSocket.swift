//
//  WebSocket.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

enum WebSocketError: Error {
    case closedUnexpectedly
    case peerDisconnected
}

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
    private var foregroundNotificationObserver: Any?
    private var backgroundNotificationObserver: Any?

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

        backgroundNotificationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didEnterBackgroundNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.requestBackgroundExecutionTime()
        }

        foregroundNotificationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            self?.endBackgroundTask()
        }
    }

    deinit {
        session.invalidateAndCancel()
        pingTimer?.invalidate()

        if let observer = self.foregroundNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = self.backgroundNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func connect() {
        if task != nil {
            disconnect()
        }

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
}

private extension WebSocket {
    enum WebSocketEvent {
        case connected
        case disconnected(URLSessionWebSocketTask.CloseCode)
        case messageReceived(String)
        case messageSent(String)
        case pingSent
        case pongReceived
        case connnectionError(Error)
    }

    func receive() {
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

    func sendPing() {
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

    func handleEvent(_ event: WebSocketEvent) {
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
            onDisconnect?(error)
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
            onDisconnect?(error)
        }
    }

    class WebSocketConnectionDelegate: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate {
        private let eventHandler: (WebSocketEvent) -> Void
        private var connectivityCheckTimer: Timer?

        init(eventHandler: @escaping (WebSocketEvent) -> Void) {
            self.eventHandler = eventHandler
        }

        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didOpenWithProtocol protocol: String?
        ) {
            connectivityCheckTimer?.invalidate()
            eventHandler(.connected)
        }

        func urlSession(
            _ session: URLSession,
            webSocketTask: URLSessionWebSocketTask,
            didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
            reason: Data?
        ) {
            eventHandler(.disconnected(closeCode))
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error {
                eventHandler(.connnectionError(error))
            } else {
                // Possibly not really necessary since connection closure would likely have been reported
                // by the other delegate method, but just to be safe. We have checks in place to prevent
                // duplicated connection closing reporting anyway.
                eventHandler(.disconnected(.normalClosure))
            }
        }

        func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
            AppLog.shared.debug("[WebSocket] waiting for connectivity...")

            // Lets not wait forever, since the user might be waiting for the connection to show in the UI.
            // It's better to show an error -if it's a new session- or else let the retry logic do its job
            DispatchQueue.main.async {
                self.connectivityCheckTimer?.invalidate()
                self.connectivityCheckTimer = Timer.scheduledTimer(
                    withTimeInterval: task.originalRequest?.timeoutInterval ?? 30,
                    repeats: false
                ) { _ in
                    // Cancelling the task should trigger an invocation to `didCompleteWithError`
                    task.cancel()
                }
            }
        }
    }
}

private extension WebSocket {
    func requestBackgroundExecutionTime() {
        if bgTaskIdentifier != .invalid {
            endBackgroundTask()
        }

        bgTaskIdentifier = UIApplication.shared.beginBackgroundTask(
            withName: "WebSocketConnection-bgTime"
        ) { [weak self] in
            self?.endBackgroundTask()
        }
    }

    func endBackgroundTask() {
        guard bgTaskIdentifier != .invalid else { return }

        UIApplication.shared.endBackgroundTask(bgTaskIdentifier)
        bgTaskIdentifier = .invalid
    }
}
