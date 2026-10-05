//
//  CollectiblesPackRevealVideoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import AVFoundation
import TangemUI

struct CollectiblesPackRevealVideoView: View {
    let player: AVPlayer

    var body: some View {
        VideoPlayerView(player: player)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}
