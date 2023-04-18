//
//  EnvironmentToggleRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct EnvironmentToggleRowView: View {
    let viewModel: EnvironmentToggleRowViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.toggle.name)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                
                if let version = viewModel.toggle.releaseVersion.version {
                    Text("version: \(version)")
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                }
            }
            
            Picker("", selection: viewModel.state) {
                ForEach(SegmentViewPicker.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .padding(16)
    }
}

struct EnvironmentToggleRowView_Preview: PreviewProvider {
    struct ContentView: View {
        @State private var state: SegmentViewPicker = .default
        var body: some View {
            EnvironmentToggleRowView(
                viewModel: EnvironmentToggleRowViewModel(toggle: .exchange, state: $state)
            )
        }
    }
    static var previews: some View {
        ContentView()
    }
}

