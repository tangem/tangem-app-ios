//
//  CircleActionButton.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct CircleActionButton: View {
	
	var action: () -> Void = { }
	var diameter: CGFloat = 40
	let backgroundColor: Color
	let imageName: String
	let isSystemImage: Bool
	let imageColor: Color
	
    var body: some View {
		Button(action: action, label: {
			ZStack {
				Circle()
					.frame(width: diameter, height: diameter, alignment: .center)
					.foregroundColor(backgroundColor)
				Group {
					if isSystemImage {
						Image(systemName: imageName)
					} else {
						Image(imageName)
					}
				}
				.font(Font.system(size: 17.0, weight: .regular, design: .default))
				.foregroundColor(imageColor)
			}
		})
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
