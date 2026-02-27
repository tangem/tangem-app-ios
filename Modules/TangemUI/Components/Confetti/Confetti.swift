//
//  ConfettiType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

public struct ConfettiView: UIViewRepresentable {
    private let shouldFireConfetti: Binding<Bool>
    private let position: ConfettiGeneratorPosition
    private let confettiLifetime: Float
    private let generationDuration: Double

    public init(
        shouldFireConfetti: Binding<Bool>,
        position: ConfettiGeneratorPosition = .aboveTop,
        confettiLifetime: Float = 4,
        generationDuration: Double = 0.3
    ) {
        self.shouldFireConfetti = shouldFireConfetti
        self.position = position
        self.confettiLifetime = confettiLifetime
        self.generationDuration = generationDuration
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = UIScreen.main.bounds
        view.isUserInteractionEnabled = false
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        if shouldFireConfetti.wrappedValue {
            launchConfetti(for: uiView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                shouldFireConfetti.wrappedValue = false
            }
        }
    }

    private func launchConfetti(for view: UIView) {
        view.layer.sublayers?.removeAll()
        let confettiLayers = ConfettiGenerator.shared
            .generateConfettiLayers(
                with:
                ConfettiGeneratorSettings(
                    generatorPosition: position,
                    generatorSize: CGSize(width: 100, height: 120),
                    confettiLifetime: confettiLifetime,
                    generationDuration: generationDuration
                )
            )

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        for layer in confettiLayers {
            view.layer.addSublayer(layer)
            layer.frame = view.bounds
        }
    }
}

struct ConfettiViewPreview: View {
    @State var shouldFireConfetti: Bool = false

    var body: some View {
        ZStack {
            ConfettiView(
                shouldFireConfetti: $shouldFireConfetti,
                position: .aboveTop,
                confettiLifetime: 4,
                generationDuration: 0.3
            )
            VStack {
                Spacer()
                Button(action: {
                    shouldFireConfetti = true
                }, label: {
                    Text("FIRE!!!!")
                        .padding()
                })
                .padding(.bottom, 40)
            }
        }
    }
}

struct ConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ConfettiViewPreview()
        }
    }
}
