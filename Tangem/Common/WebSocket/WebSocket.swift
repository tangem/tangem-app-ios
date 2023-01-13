//
//  WebSocket.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class WebSocket: NSObject {
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?

    var isConnected: Bool = false

    var request: URLRequest

    private let url: URL

    private var session: URLSession!
    private var socket: URLSessionWebSocketTask?

    init(url: URL) {
        self.url = url
        request = URLRequest(url: url)
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.shouldUseExtendedBackgroundIdleMode = true
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    func connect() {
        if socket == nil {
            socket = session.webSocketTask(with: request)
        }

        socket?.resume()
        awaitForSocketMessage()
    }

    func disconnect() {
        socket?.cancel()
        socket = nil
    }

    func write(string: String, completion: (() -> Void)?) {
        print("[WS] Attempting to send message through socket connection: \(string)")
        socket?.send(.string(string), completionHandler: { error in
            if let error {
                print("[WS] Failed to send message through socket connection. Error: \(error)")
                self.onDisconnect?(error)
                return
            }

            print("[WS] Message succesfully send to socket connection. Message: \(string)")
            completion?()
        })
    }

    private func awaitForSocketMessage() {
        socket?.receive { result in
            print("[WS] socket receive something: \(result)")
            switch result {
            case .failure(let error):
                self.disconnect()
                self.onDisconnect?(error)
                self.connect()
            case .success(let message):
                print("[WS] Receive web socket message: \(message)")
                switch message {
                case .string(let stringMessage):
                    self.onText?(stringMessage)
                case .data(let dataMessage):
                    guard let string = String(data: dataMessage, encoding: .utf8) else {
                        break
                    }

                    self.onText?(string)
                @unknown default:
                    print("Unknown socket message data type")
                    return
                }
                self.awaitForSocketMessage()
            }
        }
    }
}

extension WebSocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        guard webSocketTask == socket else {
            return
        }

        isConnected = true
        onConnect?()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        guard webSocketTask == socket else {
            return
        }

        isConnected = false
        onDisconnect?(nil)
    }

    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        // Lets not wait forever, since the user might be waiting for the connection to show in the UI.
        // It's better to show an error -if it's a new session- or else let the retry logic do its job
        //        DispatchQueue.main.async {
        //            self.connectivityCheckTimer?.invalidate()
        //            self.connectivityCheckTimer = Timer.scheduledTimer(
        //                withTimeInterval: task.originalRequest?.timeoutInterval ?? 30,
        //                repeats: false
        //            ) { _ in
        //                // Cancelling the task should trigger an invocation to `didCompleteWithError`
        //                task.cancel()
        //            }
        //        }
    }
}
