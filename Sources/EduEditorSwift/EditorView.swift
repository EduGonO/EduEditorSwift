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

    // Attempt to load index.html from Resources/ directly (no subfolder).
    if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html") {
        print("✅ Found1 index.html at:", htmlURL.path)
        webView.loadFileURL(
            htmlURL,
            allowingReadAccessTo: htmlURL.deletingLastPathComponent()
        )
    } else {
        print("❌ 1index.html not found in Bundle.main. Check that index.html is in Resources/")
        print("Bundle.main.bundlePath:", Bundle.main.bundlePath)
    }

    // Observe toolbarActions and run JS
    toolbarActions
      .sink { script in
        print("🛠 Executing JS:", script)
        webView.evaluateJavaScript(script) { result, error in
            if let err = error {
                print("❗️ JS error:", err.localizedDescription)
            }
        }
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

    // Called when page finishes loading
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🌐 WKWebView didFinish loading.")
        // Optionally inject JS to verify editor object exists:
        webView.evaluateJavaScript("typeof EduEditorBundle !== 'undefined';") { result, _ in
            print("📣 EduEditorBundle defined? →", result as? Bool ?? false)
        }
    }

    // Receive messages from JS (e.g., content updates)
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "editorHandler", let content = message.body as? String {
            print("📝 Received HTML from JS (first 60 chars):", content.prefix(60))
            parent.htmlContent = content
        }
    }
  }
}

private class BundleToken {}