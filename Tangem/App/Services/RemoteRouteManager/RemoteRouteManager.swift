//

import Combine
import Foundation

public class RemoteRouteManager {
    @Injected(\.walletConnectDeeplinkManager) private var walletConnectDeeplinkManager: WalletConnectDeeplinkManaging
    
    public private(set) var pendingRoute: RemoteRouteModel?

    private var subscriptions = Set<AnyCancellable>()
    private var responders = OrderedMulticastDelegate<RemoteRouteManagerResponder>()
    
    public init() {
        walletConnectDeeplinkManager.setDelegate(self)
    }
}

extension RemoteRouteManager: WalletConnectDeeplinkManagerDelegate {
    func didReceiveDeeplink(_ manager: WalletConnectDeeplinkManaging, remoteRoute: RemoteRouteModel) {
        self.pendingRoute = remoteRoute
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

        for delegate in responders.allDelegates.reversed() {
            if delegate.didReceiveRemoteRoute(pendingRoute) {
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
