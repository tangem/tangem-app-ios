//
//  ExpressFeatureFlagsProvider.swift
//  TangemExpress
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressFeatureFlagsProvider {
    var isApproveWithSwapEnabled: Bool { get }
}
