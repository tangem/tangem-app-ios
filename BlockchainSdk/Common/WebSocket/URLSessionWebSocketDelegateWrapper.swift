//
//  URLSessionWebSocketDelegateWrapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

class URLSessionWebSocketDelegateWrapper: NSObject, URLSessionWebSocketDelegate {
    private let webSocketTaskDidOpen: (URLSessionWebSocketTask) -> Void?
    private let webSocketTaskDidClose: (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void
    private let webSocketTaskDidCompleteWithError: (URLSessionTask, Error?) -> Void

    init(
        webSocketTaskDidOpen: @escaping (URLSessionWebSocketTask) -> Void?,
        webSocketTaskDidClose: @escaping (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void,
        webSocketTaskDidCompleteWithError: @escaping (URLSessionTask, Error?) -> Void
    ) {
        self.webSocketTaskDidOpen = webSocketTaskDidOpen
        self.webSocketTaskDidClose = webSocketTaskDidClose
        self.webSocketTaskDidCompleteWithError = webSocketTaskDidCompleteWithError
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        webSocketTaskDidOpen(webSocketTask)
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        webSocketTaskDidClose(webSocketTask, closeCode)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        webSocketTaskDidCompleteWithError(task, error)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge:
        URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let result = TangemTrustEvaluatorUtil.evaluate(challenge: challenge)
        completionHandler(result.0, result.1)
    }
}
