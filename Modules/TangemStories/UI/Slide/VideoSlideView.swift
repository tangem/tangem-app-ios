//
//  VideoSlideView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import AVFoundation

struct VideoSlideView: UIViewRepresentable {
    let player: AVPlayer?
    var contentMode: StoryContentMode = .cover

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        // Transparent so the poster underneath stays visible until the first frame renders.
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
        let gravity: AVLayerVideoGravity = contentMode == .cover ? .resizeAspectFill : .resizeAspect
        if uiView.playerLayer.videoGravity != gravity {
            uiView.playerLayer.videoGravity = gravity
        }
    }
}

final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
