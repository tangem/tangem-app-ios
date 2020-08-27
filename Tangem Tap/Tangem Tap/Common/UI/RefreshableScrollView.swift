//
//  ActivityIndicatorView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct RefreshableScrollView<Content: View>: UIViewRepresentable {
    @Binding var refreshing: Bool
    let content: () -> Content
    let host: UIHostingController<Content>
    
    internal init(refreshing: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self._refreshing = refreshing
        self.host = UIHostingController(rootView: content())
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.refreshControl = UIRefreshControl()
        scrollView.delegate = context.coordinator
        scrollView.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        let constraints = [
            host.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            host.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ]
        scrollView.addConstraints(constraints)
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Self.Context) {
        if !refreshing {
            uiView.refreshControl?.endRefreshing()
        }
        
        context.coordinator.parent.host.rootView = content()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, refreshing: $refreshing)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: RefreshableScrollView
        @Binding var refreshing: Bool
        
        init(_ parent: RefreshableScrollView, refreshing: Binding<Bool>) {
            self.parent = parent
            self._refreshing = refreshing
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if let refreshing = scrollView.refreshControl?.isRefreshing, refreshing == true {
                self.refreshing = true
            }
        }
    }
}
