//
//  NorthernLightsRendererFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Metal

enum NorthernLightsRendererFactory {
    static func makeRenderer() async -> NorthernLightsRenderer? {
        await Task.detached(priority: .userInitiated) {
            guard let device = MTLCreateSystemDefaultDevice() else {
                assertionFailure("Failed to create MTLDevice for NorthernLightsRenderer")
                return nil
            }

            do {
                return try NorthernLightsRenderer(device: device)
            } catch {
                assertionFailure("Failed to initialize NorthernLightsRenderer: \(error)")
                return nil
            }
        }.value
    }
}
