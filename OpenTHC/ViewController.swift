//
//  ViewController.swift
//  OpenTHC
//
//  Created by Theodore Newell on 4/29/17.
//  Copyright © 2017 OpenTHC. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    fileprivate var webView: WKWebView!
    fileprivate lazy var scanner = Scanner()

    fileprivate struct Constants {
        static let startingURL = URL(string: "https://weedtraqr.com/auth/app")!
        static let testScanningURL = URL(string: "https://weedtraqr.com/software/zxing")!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addWebView()
        loadStartingURL()
        addGestureRecognizers()
    }

    private func addWebView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.bounces = true
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        contentView.addSubview(webView)

        let views = ["view": contentView!, "webView": webView!]
        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|", options: NSLayoutConstraint.FormatOptions.alignAllCenterY, metrics: nil, views: views)
        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|", options: NSLayoutConstraint.FormatOptions.alignAllCenterX, metrics: nil, views: views)
        let constraints = horizontal + vertical
        contentView.addConstraints(constraints)
    }

    private func loadStartingURL() {
        let startingURL: URL
        if Platform.isSimulator {
            startingURL = Constants.testScanningURL
        } else {
            startingURL = Constants.startingURL
        }
        load(url: startingURL)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc func refreshWebView(sender: UIRefreshControl) {
        loadStartingURL()
        sender.endRefreshing()
    }

    func addGestureRecognizers() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(goBack))
        swipeLeft.direction = .right
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(goForward))
        swipeRight.direction = .left
        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)
    }
}

extension ViewController {
    @objc func goBack() {
        webView.goBack()
    }

    @objc func goForward() {
        webView.goForward()
    }
}

extension ViewController {
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard Platform.isSimulator else {
            return
        }
        if motion == .motionShake {
            load(url: Constants.testScanningURL)
        }
    }
}

extension ViewController: WKUIDelegate {
    
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            return decisionHandler(.allow)
        }
        if url.scheme == "zxing" && url.host == "scan" {
            decisionHandler(.cancel)
            handleScanURL(url)
        } else {
            decisionHandler(.allow)
        }
    }

    private func handleScanURL(_ url: URL) {
        guard let reader = URLQueryReader(url: url), let macroURI = reader.parameter(for: "ret") else {
            print("Error parsing url: \(url)")
            return
        }
        scanner.present(from: self) { scannedValue in
            guard let value = scannedValue else {
                print("Did not scan a value")
                return
            }
            self.loadURI(macroURI, withScannedValue: value)
        }
    }

    private func loadURI(_ uri: String, withScannedValue scanned: String) {
        guard let encodedValue = scanned.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            print("Failed to percent-encode scanned value: \(scanned)")
            return
        }
        let fullURI = uri.replacingOccurrences(of: "{CODE}", with: encodedValue)
        guard let continueAfterScanURL = URL(string: fullURI) else {
            print("Return URI could not be converted to URL: \(fullURI)")
            return
        }
        load(url: continueAfterScanURL)
    }
}

class URLQueryReader {
    private let components: URLComponents
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        self.components = components
    }

    func parameter(for key: String) -> String? {
        return components.queryItems?.first(where: {$0.name == key})?.value
    }
}

