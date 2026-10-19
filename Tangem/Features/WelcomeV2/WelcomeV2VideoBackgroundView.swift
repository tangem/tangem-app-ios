//
//  WelcomeV2VideoBackgroundView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import AVFoundation

struct WelcomeV2VideoBackgroundView: View {
    @ObservedObject var viewModel: WelcomeV2VideoBackgroundViewModel

    var body: some View {
        PlayerLayerRepresentable(player: viewModel.player)
            .background(Color.black)
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.stop() }
    }

    private struct PlayerLayerRepresentable: UIViewRepresentable {
        let player: AVPlayer?

        func makeUIView(context: Context) -> Container {
            let view = Container()
            view.backgroundColor = .black
            return view
        }

        func updateUIView(_ uiView: Container, context: Context) {
            uiView.player = player
        }

        final class Container: UIView {
            private let backdropView = PlayerView()
            private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            private let foregroundView = PlayerView()

            var player: AVPlayer? {
                didSet {
                    backdropView.playerLayer.player = player
                    foregroundView.playerLayer.player = player
                }
            }

            override init(frame: CGRect) {
                super.init(frame: frame)
                backdropView.playerLayer.videoGravity = .resizeAspectFill
                [backdropView, blurView, foregroundView].forEach(addSubview)
            }

            @available(*, unavailable)
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            override func layoutSubviews() {
                super.layoutSubviews()

                let isWide = bounds.width > bounds.height

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                [backdropView, blurView, foregroundView].forEach { $0.frame = bounds }
                backdropView.isHidden = !isWide
                blurView.isHidden = !isWide
                foregroundView.playerLayer.videoGravity = isWide ? .resizeAspect : .resizeAspectFill
                CATransaction.commit()
            }
        }

        final class PlayerView: UIView {
            override class var layerClass: AnyClass { AVPlayerLayer.self }
            var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        }
    }
}
