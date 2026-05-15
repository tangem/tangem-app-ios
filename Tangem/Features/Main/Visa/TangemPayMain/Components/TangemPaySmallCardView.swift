//
//  TangemPaySmallCardView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TangemPaySmallCardView: View {
    enum State {
        case active(cardNumberEnd: String)
        case replacing
    }

    let state: State

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch state {
            case .active:
                Color.Tangem.Visa.cardDetailBackground

                LinearGradient(
                    colors: [
                        .clear,
                        Color.Tangem.Button.backgroundAccent.opacity(0.5),
                    ],
                    startPoint: UnitPoint(x: 0.1, y: 0.85),
                    endPoint: UnitPoint(x: 0.95, y: 0.0)
                )
            case .replacing:
                Color.Tangem.Graphic.Neutral.quaternary
            }

            Text("VISA")
                .font(.system(size: 7, weight: .bold))
                .italic()
                .foregroundColor(.white)
                .padding(.leading, 27)
                .padding(.top, 3)

            bottomLeadingContent
                .padding(.leading, 3)
                .padding(.top, 20)
        }
        .frame(width: 48, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Colors.Stroke.primary.opacity(0.1), location: 0),
                            .init(color: Colors.Stroke.primary, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var bottomLeadingContent: some View {
        switch state {
        case .active(let cardNumberEnd):
            Text(cardNumberEnd)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white)
                .tracking(0.06)
        case .replacing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
