//
//  WelcomeBackgroundView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeBackgroundView: View {
    var body: some View {
        Circle()
            .strokeBorder(borderGradient, lineWidth: 10)
            .background(Circle().fill(gradient).padding(30))
    }
    
    private var gradient: LinearGradient {
        let colors: [Color] = [Color(.sRGB,
                                     red: 244.0/255.0,
                                     green: 244.0/255.0,
                                     blue: 244.0/255.0,
                                     opacity: 1),
                               Color(.sRGB,
                                     red: 248.0/255.0,
                                     green: 248.0/255.0,
                                     blue: 248.0/255.0,
                                     opacity: 0.26)]

        return LinearGradient(gradient: Gradient(colors: colors),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }
    
    private var borderGradient: LinearGradient {
        let colors: [Color] = [Color(.sRGB,
                                     red: 252.0/255.0,
                                     green: 252.0/255.0,
                                     blue: 252.0/255.0,
                                     opacity: 1),
                               Color(.sRGB,
                                     red: 228.0/255.0,
                                     green: 228.0/255.0,
                                     blue: 228.0/255.0,
                                     opacity: 0)]

        return LinearGradient(gradient: Gradient(colors: colors),
                              startPoint: .top,
                              endPoint: .bottom)
    }
}

struct WelcomeBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeBackgroundView()
    }
}
