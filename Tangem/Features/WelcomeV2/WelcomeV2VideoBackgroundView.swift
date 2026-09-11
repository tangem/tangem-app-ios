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
            uiView.playerLayer.player = player
            uiView.playerLayer.videoGravity = .resizeAspectFill
        }

        final class Container: UIView {
            override class var layerClass: AnyClass { AVPlayerLayer.self }
            var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        }
    }
}
