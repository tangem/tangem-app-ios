//
//  CircleActionButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct CircleActionButton: View {
	
    var action: () -> Void = { }
    var diameter: CGFloat = 41
    let backgroundColor: Color
    let imageName: String
    let isSystemImage: Bool
    let imageColor: Color
    var withVerification: Bool = false
    var isDisabled = false
	
    @State private var isVerify = false
    
    var image: Image {
        isSystemImage ?
            Image(systemName: imageName) :
            Image(imageName)
    }
    
    var body: some View {
        Button(action: {
            action()
            if withVerification {
                playVerifyAnimation()
            }
        }, label: {
            ZStack {
                Circle()
                    .frame(width: diameter, height: diameter, alignment: .center)
                    .foregroundColor(isVerify ? Color.tangemGreen : backgroundColor)
                Group {
                    if isVerify {
                        Image(systemName: "checkmark")
                    } else {
                        image
                    }
                }
                .font(Font.system(size: 17.0, weight: .light, design: .default))
                .foregroundColor(isVerify ? Color.white : imageColor)
            }
            .overlay(!isDisabled ? Color.clear : Color.white.opacity(0.4))
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    private func playVerifyAnimation() {
        withAnimation {
            isVerify = true
        }
        
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                isVerify = false
            }
        }
    }
}

struct CircleActionButton_Previews: PreviewProvider {
    static var previews: some View {
        CircleActionButton(diameter: 40,
                           backgroundColor: .tangemBgGray,
                           imageName: "doc.on.clipboard",
                           isSystemImage: true,
                           imageColor: .tangemGrayDark6)
    }
}
