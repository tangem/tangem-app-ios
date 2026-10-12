//
//  HostNamedDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A destination named by the host of our own scheme: `tangem://<host>`. It reads the link itself and says
/// which action it becomes, so everything about it — the host, the names of the parameters only it reads and
/// the rules they have to satisfy — lives in its own file. Shared in one place are only the parameter names
/// several destinations read.
///
/// Adding a destination means its own file, a case in `DeeplinkNavigationAction` and a line in
/// `destinationsNamedByHost`, and the screen it opens in the deeplink presenter. The exhaustive switches
/// there won't compile until the new destination is answered — which is where the product decision belongs.
protocol HostNamedDeeplink {
    static var host: String { get }

    init(link: DeeplinkURL) throws

    var action: DeeplinkNavigationAction { get }
}
