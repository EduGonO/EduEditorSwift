import SwiftUI
import WebKit
import Combine

public struct EditorView: UIViewRepresentable {
  @Binding var htmlContent: String
  let toolbarActions: PassthroughSubject<String, Never> = .init()

  public init(htmlContent: Binding<String>) {
    self._htmlContent = htmlContent
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  public func makeUIView(context: Context) -> WKWebView {
    let webConfig = WKWebViewConfiguration()
    let userController = WKUserContentController()
    userController.add(context.coordinator, name: "editorHandler")
    webConfig.userContentController = userController

    let webView = WKWebView(frame: .zero, configuration: webConfig)
    webView.navigationDelegate = context.coordinator

    // Load the local HTML
    if let htmlURL = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "EditorBundle") {
      webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
    }

    // Observe toolbar actions and dispatch to JS
    toolbarActions
      .sink { script in
        webView.evaluateJavaScript(script, completionHandler: nil)
      }
      .store(in: &context.coordinator.cancellables)

    return webView
  }

  public func updateUIView(_ webView: WKWebView, context: Context) {
    // Nothing to update; editor lives in JS.
  }

  public class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: EditorView
    var cancellables = Set<AnyCancellable>()

    init(_ parent: EditorView) {
      self.parent = parent
    }

    // Receive messages from JS (e.g., content updates)
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if message.name == "editorHandler", let content = message.body as? String {
        parent.htmlContent = content
      }
    }
  }
}