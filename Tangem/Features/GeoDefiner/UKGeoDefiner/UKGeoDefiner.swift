//
//  UKGeoDefiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol UKGeoDefiner: Initializable {
    func waitForGeoIpRegionIfNeeded() async
    var isUK: Bool { get }
}

private struct UKGeoDefinerKey: InjectionKey {
    static var currentValue: UKGeoDefiner = CommonUKGeoDefiner()
}

extension InjectedValues {
    var ukGeoDefiner: UKGeoDefiner {
        get { Self[UKGeoDefinerKey.self] }
        set { Self[UKGeoDefinerKey.self] = newValue }
    }
}
