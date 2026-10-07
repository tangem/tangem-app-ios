//
//  VideoPlayerView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import AVFoundation

public struct VideoPlayerView: UIViewRepresentable {
    private let player: AVPlayer?
    private let contentMode: ContentMode

    public init(player: AVPlayer?, contentMode: ContentMode = .fill) {
        self.player = player
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> Container {
        let view = Container()
        // Transparent so the poster underneath stays visible until the first frame renders.
        view.backgroundColor = .clear
        return view
    }

    public func updateUIView(_ uiView: Container, context: Context) {
        guard let playerLayer = uiView.playerLayer else { return }

        if playerLayer.player !== player {
            playerLayer.player = player
        }
        let gravity: AVLayerVideoGravity = contentMode == .fill ? .resizeAspectFill : .resizeAspect
        if playerLayer.videoGravity != gravity {
            playerLayer.videoGravity = gravity
        }
    }
}

public extension VideoPlayerView {
    final class Container: UIView {
        override public class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    }
}
