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
    enum ConnectionState {
        case notConnected
        case connecting
        case connected
        case disconnecting
    }

    let url: URL

    var request: URLRequest
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?

    private let pingInterval: TimeInterval = 30
    private let timeoutInterval: TimeInterval = 20

    var isConnected: Bool { state == .connected }

    private var state: ConnectionState = .notConnected
    private var isWaitingForMessage: Bool = false

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
        AppLog.shared.debug("[WC 2.0 WebSocket] Initializing new WebSocket for url: \(url)")
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
        AppLog.shared.debug("[WC 2.0 WebSocket] Deinitializing WebSocket with url: \(url)")
        session.invalidateAndCancel()
        pingTimer?.invalidate()
    }

    private func address(for object: AnyObject) -> UnsafeMutableRawPointer {
        Unmanaged.passUnretained(object).toOpaque()
    }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()

    func connect() {
        log("Attempting to connect WebSocket with state \(state) to \(url)")
        guard state == .notConnected else {
            return
        }
        if task != nil {
            log("Attempting to create task for request: \(request). Current task: \(address(for: task!))")
            disconnect()
        }
        state = .connecting
        task = session.webSocketTask(with: request)
        log("New task created: \(address(for: task!))")
        task?.resume()
        receive()
    }

    func disconnect() {
        log("Disconnecting WebSocket with state: \(state) with \(url)")
        pingTimer?.invalidate()
        pingTimer = nil
        state = .notConnected
        if task == nil {
            return
        }

        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    func write(string text: String, completion: (() -> Void)?) {
        guard isConnected else { return }

        log("Writing text: \(text) to socket")
        task?.send(.string(text)) { [weak self] error in
            if let error = error {
                self?.handleEvent(.connnectionError(error))
            } else {
                completion?()
                self?.handleEvent(.messageSent(text))
            }
        }
    }

    private lazy var memoryAddress = Unmanaged.passUnretained(self).toOpaque()

    private func log(_ message: String) {
        if AppEnvironment.current.isDebug {
            print("\(dateFormatter.string(from: Date())): [WC 2.0 WebSocket] \(memoryAddress). ✉️ Message: \(message)")
        }
    }

    private func receive() {
        guard let task = task else { return }

        if isWaitingForMessage {
            log("Already waiting for new message. Ignoring call")
            return
        }

        isWaitingForMessage = true
        log("Waiting for new message through \(url)")
        task.receive { [weak self] result in
            self?.isWaitingForMessage = false
            switch result {
            case .success(let message):
                self?.log("Receive message: \(message)")
                if case .string(let text) = message {
                    self?.log("Received message is string message. Message text \(text). Handling received message")
                    self?.handleEvent(.messageReceived(text))
                }
                self?.receive()
            case .failure(let error):
                self?.log("Socket receive failure message with error: \(error)")
                self?.handleEvent(.connnectionError(error))
            }
        }
    }

    private func setupPingTimer() {
        log("Scheduling ping timer")
        if pingTimer != nil {
            log("Ping timer not nil: \(address(for: pingTimer!))")
            pingTimer?.invalidate()
            pingTimer = nil
            log("Ping timer should be invalidated: \(pingTimer)")
        }
        DispatchQueue.main.async {
            self.pingTimer = Timer.scheduledTimer(
                withTimeInterval: self.pingInterval,
                repeats: true
            ) { [weak self] timer in
                self?.log("Scheduled ping timer fired: \(self?.address(for: timer))")
                self?.sendPing()
            }
            self.log("New ping timer")
        }
    }

    private func sendPing() {
        guard isConnected else { return }

        log("Attempting to send ping")
        task?.sendPing(pongReceiveHandler: { [weak self] error in
            if let error {
                self?.log("Failed to send ping message: \(error)")
                self?.handleEvent(.connnectionError(error))
                return
            }

            self?.log("Receive pong message")
            self?.handleEvent(.pongReceived)
        })
        handleEvent(.pingSent)
    }

    private func handleEvent(_ event: WebSocketEvent) {
        switch event {
        case .connected:
            state = .connected
            setupPingTimer()
            log("Successfully connected. Sending message to onConnect closure")
            onConnect?()
        case .disconnected(let closeCode):
            log("Receive disconnect event. Close code: \(closeCode)")
            guard isConnected else { break }

            state = .notConnected
            pingTimer?.invalidate()

            var error: Error?
            let closeCodeDescription = String(describing: closeCode.rawValue)
            switch closeCode {
            case .normalClosure:
                log("💥💥💥 disconnected (normal closure)")
                return
            case .abnormalClosure, .goingAway:
                log("💥💥💥 disconnected close code (peer disconnected) - \(closeCodeDescription)")
                error = WebSocketError.peerDisconnected
            default:
                log("💥💥💥 disconnected with not specified close code - \(closeCodeDescription)")
                error = WebSocketError.closedUnexpectedly
            }
            disconnectOnMainThread(with: error)
        case .messageReceived(let text):
            onText?(text)
        case .messageSent(let text):
            log("==> Message successfully sent \(text)")
        case .pingSent:
            log("==> Ping sent")
        case .pongReceived:
            log("<== Pong received")
        case .connnectionError(let error):
            log("Connection error: \(error.localizedDescription)")
//            disconnectOnMainThread(with: error)
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
            log("Sending onDisconnect event without switching to main thread")
            onDisconnect?(error)
            return
        }

        DispatchQueue.main.async {
            self.log("Switching to main thread to send onDisconnect event")
            self.onDisconnect?(error)
        }
    }
}
