//
//  ContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct ContentView<Content: View>: View {
    let content: () -> Content
    init (@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        NavigationView {
            content()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView() {
            Text("Hello")
        }
        .previewGroup(devices: [.iPhone12Pro])
    }
}
