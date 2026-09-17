//
//  DeeplinkOverlayResult.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// What a destination answers with. Most overlays are ready the moment they are asked for; a couple need data
/// that hasn't arrived yet, and the link is claimed now and shown when it lands.
enum DeeplinkOverlayResult {
    case ready(OverlayView)
    /// Isolated to the main actor like everything an overlay is built from: what is awaited inside is data,
    /// and the coordinator and the view are made here when it lands.
    case loading(@MainActor () async -> OverlayView?)
}

extension DeeplinkOverlayResult {
    /// For a screen whose data is still on its way. Answering with this claims the link.
    static func whenReady(_ load: @escaping @MainActor () async -> OverlayView?) -> DeeplinkOverlayResult {
        .loading(load)
    }
}
