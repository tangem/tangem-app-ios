//
//  SafariView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import SafariServices
import WebKit


struct WebViewContainer: View {
    var url: URL?
    var closeUrl: String? = nil
    var title: LocalizedStringKey
    @Environment(\.presentationMode) var presentationMode
    
    var urlActions: [String : (() -> Void)]  {
        if let closeUrl = closeUrl {
            return [closeUrl: {
                self.presentationMode.wrappedValue.dismiss()
            }]
        } else {
            return [:]
        }
    }
    
    var body: some View {
        WebView(url: url, urlActions: urlActions)
            .navigationBarTitle(title, displayMode: .inline)
            .background(Color.tangemTapBg.edgesIgnoringSafeArea(.all))
    }
}


struct WebView: UIViewRepresentable {
    var url: URL?
    var urlActions: [String : (() -> Void)] = [:]
    
    func makeUIView(context: Context) -> WKWebView {
        let view =  WKWebView()
        if let url = url {
            view.load(URLRequest(url: url))
        }
        view.navigationDelegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let urlActions: [String: (() -> Void)]
        
        init(urlActions: [String : (() -> Void)] = [:]) {
            self.urlActions = urlActions
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            
            if let url = navigationAction.request.url?.absoluteString.split(separator: "?").first,
               let actionForURL = urlActions[String(url).removeLatestSlash()] {
                decisionHandler(.cancel)
                actionForURL()
                return
            }
            
            decisionHandler(.allow)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(urlActions: urlActions)
    }
}

//class CustomSafariViewController: UIViewController {
//    var url: URL!
//    //{
//      //  didSet {
//            // when url changes, reset the safari child view controller
//           // configureChildViewController()
//   //     }
//   // }
//
//    private var webView = WKWebView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.addSubview(webView)
//       // configureChildViewController()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        webView.load(URLRequest(url: url))
//    }
//
////    private func configureChildViewController() {
////        // Remove the previous safari child view controller if not nil
////        if let safariViewController = safariViewController {
////            safariViewController.willMove(toParent: self)
////            safariViewController.view.removeFromSuperview()
////            safariViewController.removeFromParent()
////            self.safariViewController = nil
////        }
////
////        // Create a new safari child view controller with the url
////        let newSafariViewController = SFSafariViewController(url: url)
////        addChild(newSafariViewController)
////        newSafariViewController.view.frame = view.frame
////        view.addSubview(newSafariViewController.view)
////        newSafariViewController.didMove(toParent: self)
////        self.safariViewController = newSafariViewController
////    }
//}
