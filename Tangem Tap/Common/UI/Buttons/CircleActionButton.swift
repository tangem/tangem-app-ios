//
//  CircleActionButton.swift
//  Tangem Tap
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
					.foregroundColor(isVerify ? Color.tangemTapGreen : backgroundColor)
				Group {
                    if isVerify {
                        Image("checkmark")
                    } else {
                        if isSystemImage {
                            Image(systemName: imageName)
                        } else {
                            Image(imageName)
                        }
                    }
				}
				.font(Font.system(size: 17.0, weight: .light, design: .default))
                .foregroundColor(isVerify ? Color.white : imageColor)
                .overlay( !isDisabled ? Color.clear : Color.white.opacity(0.4))
			}
		})
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
						   backgroundColor: .tangemTapBgGray,
						   imageName: "doc.on.clipboard",
						   isSystemImage: false,
						   imageColor: .tangemTapGrayDark6)
    }
}
