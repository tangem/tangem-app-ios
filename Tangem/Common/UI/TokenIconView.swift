//
//  TokenIconView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

struct TokenIconView: View {
    
    var token: TokenItem
    
    var body: some View {
        if let path = token.imagePath, let url = URL(string: path) {
            KFImage(url)
                .resizable()
                .placeholder {
                    token.imageView
                }
                .fade(duration: 0.3)
        } else {
            token.imageView
        }
    }
    
}
