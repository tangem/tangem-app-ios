//
//  CheckmarkSwitch.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct CheckmarkSwitch: View {
    struct Settings {
        let shape: Shape
        let color: Color
        let borderColor: Color
        let checkmarkLineWidth: CGFloat
        let isInteractable: Bool

        static func defaultCircled(interactable: Bool = true) -> Settings {
            .init(
                shape: .circle,
                color: Colors.Control.checked,
                borderColor: Colors.Old.tangemGrayDark,
                checkmarkLineWidth: 2,
                isInteractable: interactable
            )
        }

        static func defaultRoundedRect(interactable: Bool = true) -> Settings {
            .init(
                shape: .roundedRect(cornerRadius: 3),
                color: Colors.Control.checked,
                borderColor: Colors.Old.tangemGrayDark,
                checkmarkLineWidth: 2,
                isInteractable: interactable
            )
        }
    }

    enum Shape {
        case circle
        case roundedRect(cornerRadius: CGFloat)

        func cornerRadius(in containerSize: CGSize) -> CGFloat {
            switch self {
            case .circle:
                return containerSize.height / 2
            case .roundedRect(let cornerRadius):
                return cornerRadius
            }
        }
    }

    var isChecked: Binding<Bool>
    var settings: Settings

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch settings.shape {
                case .circle:
                    Circle()
                        .strokeBorder(settings.borderColor, lineWidth: 2)
                case .roundedRect(let radius):
                    Rectangle()
                        .strokeBorder(settings.borderColor, lineWidth: 2)
                        .cornerRadius(radius)
                }
                Rectangle()
                    .foregroundColor(settings.color)
                    .cornerRadius(settings.shape.cornerRadius(in: geometry.size))
                    .scaleEffect(.init(
                        width: isChecked.wrappedValue ? 1.0 : 0.0001,
                        height: isChecked.wrappedValue ? 1.0 : 0.0001
                    ))
                Checkmark(
                    lineWidth: 2,
                    filled: isChecked.wrappedValue
                )
            }
            .onTapGesture {
                guard settings.isInteractable else { return }

                withAnimation {
                    isChecked.wrappedValue.toggle()
                }
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isEvenChecked = false
    @Previewable @State var isOddChecked = true

    VStack {
        CheckmarkSwitch(
            isChecked: $isOddChecked,
            settings: .defaultCircled()
        )
        .frame(size: .init(width: 26, height: 26))
        CheckmarkSwitch(
            isChecked: $isEvenChecked,
            settings: .defaultCircled()
        )
        .frame(size: .init(width: 26, height: 26))
        CheckmarkSwitch(
            isChecked: $isOddChecked,
            settings: .defaultRoundedRect()
        )
        .frame(size: .init(width: 26, height: 26))
        CheckmarkSwitch(
            isChecked: $isEvenChecked,
            settings: .defaultRoundedRect()
        )
        .frame(size: .init(width: 26, height: 26))
    }
}
