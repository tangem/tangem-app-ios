//
//  ConfettiType.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ConfettiView: UIViewRepresentable {
    var shouldFireConfetti: Binding<Bool>
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = UIScreen.main.bounds
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if shouldFireConfetti.wrappedValue {
            launchConfetti(for: uiView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.shouldFireConfetti.wrappedValue = false
            }
            
        }
    }
    
    private func launchConfetti(for view: UIView) {
        view.layer.sublayers?.removeAll()
        let confettiLayers = ConfettiGenerator.shared
            .generateConfettiLayers(
                with:
                    ConfettiGeneratorSettings(generatorPosition: .aboveTop,
                                              generatorSize: CGSize(width: 100, height: 120),
                                              confettiLifetime: 4.5,
                                              generationDuration: 1)
        )
        for layer in confettiLayers {
            view.layer.addSublayer(layer)
            layer.frame = view.bounds
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

