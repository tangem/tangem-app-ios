//
//  AppDelegate+DeepLinkDelegate.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import AppsFlyerLib

extension AppDelegate: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        switch result.status {
        case .notFound:
            AppsflyerLogger.info("Deep link not found")
            return
        case .failure:
            if let error = result.error {
                AppsflyerLogger.error(error: error)
            } else {
                AppsflyerLogger.info("Deep link not handled because of unknown error")
            }
            return
        case .found:
            AppsflyerLogger.info("Deep link found")
        }

        guard let deepLink = result.deepLink else {
            AppsflyerLogger.info("Could not extract deep link object")
            return
        }

        let deepLinkStr: String = deepLink.toString()
        AppsflyerLogger.info("DeepLink data is: \(deepLinkStr)")

        let deepLinkType = deepLink.isDeferred ? "deferred" : "direct"
        AppsflyerLogger.info("This is a \(deepLinkType) deep link")

        let resolver = AppsFlyerDeepLinkResolver()
        resolver.resolveDeeplink(deepLink)
    }
}
