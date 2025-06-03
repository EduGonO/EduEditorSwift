import SwiftUI
import Combine

public struct ToolbarView: View {
  let sendCommand: (String) -> Void

  public init(sendCommand: @escaping (String) -> Void) {
    self.sendCommand = sendCommand
  }

  public var body: some View {
    HStack {
      Button(action: { sendCommand("editor.formatBold()") }) {
        Image(systemName: "bold")
      }
      .padding()

      Button(action: { sendCommand("editor.formatItalic()") }) {
        Image(systemName: "italic")
      }
      .padding()

      Button(action: { sendCommand("editor.insertLink('https://')") }) {
        Image(systemName: "link")
      }
      .padding()

      // Add more buttons matching Novel’s JS API
    }
    .background(Color(UIColor.secondarySystemBackground))
  }
}