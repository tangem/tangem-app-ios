//
//  Analytics+WalletConnectDebugEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum WalletConnectDebugEvent {
        case webSocketConnected
        case webSocketDisconnected(closeCode: String, connectionState: String)
        case webSocketReceiveText
        case webSocketConnectionError(error: Error)
        case attemptingToOpenSession(url: String)
        case receiveSessionProposal(name: String, dAppURL: String)
        case receiveRequestFromDApp(method: String)
        case errorShownToTheUser(error: String)
    }
}

extension Analytics.WalletConnectDebugEvent: AnalyticsDebugEvent {
    var title: String {
        let prefix = "[WalletConnect Debug] "
        let webSocketPrefix = "Web socket "
        let suffix: String
        switch self {
        case .webSocketConnected:
            suffix = webSocketPrefix + "connected"
        case .webSocketDisconnected:
            suffix = webSocketPrefix + "receive disconnected event"
        case .webSocketReceiveText:
            suffix = webSocketPrefix + "receive text"
        case .webSocketConnectionError:
            suffix = webSocketPrefix + "receive connection error"
        case .attemptingToOpenSession:
            suffix = "Attempting to open new session"
        case .receiveSessionProposal:
            suffix = "Receive session proposal"
        case .receiveRequestFromDApp:
            suffix = "Receive request from dApp"
        case .errorShownToTheUser:
            suffix = "WalletConnectV2Service displays error to user"
        }

        return prefix + suffix
    }

    var analyticsParams: [String: Any] {
        switch self {
        case .webSocketConnected, .webSocketReceiveText:
            return [:]
        case .webSocketDisconnected(let closeCode, let connectionState):
            return [
                ParamKey.webSocketCloseCode.rawValue: closeCode,
                ParamKey.webSocketState.rawValue: connectionState,
            ]
        case .webSocketConnectionError(let error):
            return [ParamKey.webSocketConnectionError.rawValue: error.localizedDescription]
        case .attemptingToOpenSession(let url):
            return [ParamKey.dAppPairingURL.rawValue: url]
        case .receiveSessionProposal(let name, let dAppURL):
            return [
                ParamKey.dAppName.rawValue: name,
                ParamKey.dAppURL.rawValue: dAppURL,
            ]
        case .receiveRequestFromDApp(let method):
            return [
                ParamKey.requestMethod.rawValue: method,
            ]
        case .errorShownToTheUser(let error):
            return [
                ParamKey.errorShownToTheUser.rawValue: error,
            ]
        }
    }
}

private extension Analytics.WalletConnectDebugEvent {
    enum ParamKey: String {
        case webSocketCloseCode
        case webSocketState
        case webSocketConnectionError
        case dAppPairingURL
        case dAppName
        case dAppURL
        case requestMethod
        case errorShownToTheUser
    }
}
