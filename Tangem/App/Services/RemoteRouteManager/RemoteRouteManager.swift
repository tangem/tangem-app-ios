//
//  RemoteRouteManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import Foundation

public class RemoteRouteManager {
    @Injected(\.deeplinkParser) private var deeplinkParser: DeeplinkParsing

    public private(set) var pendingRoute: RemoteRouteModel?
    private var responders = OrderedWeakObjectsCollection<RemoteRouteManagerResponder>()

    public init() {
        deeplinkParser.delegate = self
    }

    deinit {
        deeplinkParser.delegate = nil
    }
}

// MARK: - DeeplinkManagerDelegate

extension RemoteRouteManager: DeeplinkManagerDelegate {
    public func didReceiveDeeplink(_ manager: DeeplinkParsing, remoteRoute: RemoteRouteModel) {
        pendingRoute = remoteRoute
        tryHandleLastRoute()
    }
}

// MARK: - RemoteRouteManaging

extension RemoteRouteManager: RemoteRouteManaging {
    public func becomeFirstResponder(_ responder: RemoteRouteManagerResponder) {
        responders.add(responder)
    }

    public func resignFirstResponder(_ responder: RemoteRouteManagerResponder) {
        responders.remove(responder)
    }

    public func tryHandleLastRoute() {
        guard let pendingRoute = pendingRoute else {
            return
        }

        for responder in responders.allDelegates.reversed() {
            if responder.didReceiveRemoteRoute(pendingRoute) {
                break
            }
        }
    }

    public func clearPendingRoute() {
        pendingRoute = nil
    }
}

public enum RemoteRouteModel {
    case walletConnect(URL) // [REDACTED_TODO_COMMENT]
}
