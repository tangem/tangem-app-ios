//
//  LearnView.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct LearnView: View {
    @ObservedObject private var viewModel: LearnViewModel

    init(viewModel: LearnViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
}

struct LearnView_Preview: PreviewProvider {
    static let viewModel = LearnViewModel(coordinator: LearnCoordinator())

    static var previews: some View {
        LearnView(viewModel: viewModel)
    }
}
