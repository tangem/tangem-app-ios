//
//  SupportDeeplink+Overlay.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// The chat Details opens, over whatever the user is looking at. A link asks for the chat itself, so the
/// choice between mail and chat is not part of it.
extension SupportDeeplink: DeeplinkOverlayProviding {
    func makeOverlay(in context: DeeplinkOverlayContext) -> DeeplinkOverlayResult? {
        let viewModel = SupportChatViewModel(input: SupportChatInputFactory().makeInput(source: .deeplink))

        return .ready(context.sheet(context.embedInNavigationStack { SupportChatView(viewModel: viewModel) }))
    }
}
