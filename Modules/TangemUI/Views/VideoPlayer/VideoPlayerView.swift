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
    private let fitsWithBlurredBackdropWhenWide: Bool

    public init(player: AVPlayer?, contentMode: ContentMode = .fill, fitsWithBlurredBackdropWhenWide: Bool = false) {
        self.player = player
        self.contentMode = contentMode
        self.fitsWithBlurredBackdropWhenWide = fitsWithBlurredBackdropWhenWide
    }

    public func makeUIView(context: Context) -> Container {
        let view = Container()
        // Transparent so the poster underneath stays visible until the first frame renders.
        view.backgroundColor = .clear
        return view
    }

    public func updateUIView(_ uiView: Container, context: Context) {
        uiView.update(
            player: player,
            gravity: contentMode == .fill ? .resizeAspectFill : .resizeAspect,
            fitsWithBlurredBackdropWhenWide: fitsWithBlurredBackdropWhenWide
        )
    }
}

public extension VideoPlayerView {
    final class Container: UIView {
        private let backdropView = PlayerLayerView()
        private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        private let foregroundView = PlayerLayerView()

        private var player: AVPlayer?
        private var gravity: AVLayerVideoGravity = .resizeAspectFill
        private var fitsWithBlurredBackdropWhenWide = false

        override init(frame: CGRect) {
            super.init(frame: frame)
            backdropView.playerLayer.videoGravity = .resizeAspectFill
            [backdropView, blurView, foregroundView].forEach(addSubview)
            applyLayout()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            applyLayout()
        }

        func update(player: AVPlayer?, gravity: AVLayerVideoGravity, fitsWithBlurredBackdropWhenWide: Bool) {
            guard
                self.player !== player
                || self.gravity != gravity
                || self.fitsWithBlurredBackdropWhenWide != fitsWithBlurredBackdropWhenWide
            else {
                return
            }

            self.player = player
            self.gravity = gravity
            self.fitsWithBlurredBackdropWhenWide = fitsWithBlurredBackdropWhenWide
            applyLayout()
        }

        private func applyLayout() {
            let showsBackdrop = fitsWithBlurredBackdropWhenWide && bounds.width > bounds.height

            CATransaction.begin()
            CATransaction.setDisableActions(true)

            [backdropView, blurView, foregroundView].forEach { $0.frame = bounds }
            backdropView.isHidden = !showsBackdrop
            blurView.isHidden = !showsBackdrop
            backdropView.setPlayer(showsBackdrop ? player : nil)
            foregroundView.setPlayer(player)
            foregroundView.setGravity(showsBackdrop ? .resizeAspect : gravity)

            CATransaction.commit()
        }
    }
}

private final class PlayerLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    func setPlayer(_ player: AVPlayer?) {
        if playerLayer.player !== player {
            playerLayer.player = player
        }
    }

    func setGravity(_ gravity: AVLayerVideoGravity) {
        if playerLayer.videoGravity != gravity {
            playerLayer.videoGravity = gravity
        }
    }
}
