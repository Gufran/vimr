/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class AppDelegateReducer {

  typealias Pair = StateActionPair<AppState, AppDelegate.Action>

  init(baseServerUrl: URL) {
    self.baseServerUrl = baseServerUrl
  }

  func reduce(_ pair: Pair) -> Pair {
    var state = pair.state

    switch pair.action {

    case let .newMainWindow(urls, cwd):
      let mainWindow = self.newMainWindow(with: state, urls: urls, cwd: cwd)
      state.mainWindows[mainWindow.uuid] = mainWindow

    case let .openInKeyWindow(urls, cwd):
      guard let uuid = state.currentMainWindowUuid, state.mainWindows[uuid] != nil else {
        let mainWindow = self.newMainWindow(with: state, urls: urls, cwd: cwd)
        state.mainWindows[mainWindow.uuid] = mainWindow
        break
      }

      state.mainWindows[uuid]?.urlsToOpen = urls.toDict { url in MainWindow.OpenMode.default }
      state.mainWindows[uuid]?.cwd = cwd

    case .preferences:
      state.preferencesOpen = Marked(true)

    case .cancelQuit:
      state.quitWhenNoMainWindow = false

    case .quitWithoutSaving, .quit:
      state.mainWindows.keys.forEach { state.mainWindows[$0]?.close = true }
      state.quitWhenNoMainWindow = true

    }

    return StateActionPair(state: state, action: pair.action)
  }

  fileprivate let baseServerUrl: URL

  fileprivate func newMainWindow(with state: AppState, urls: [URL], cwd: URL) -> MainWindow.State {
    var mainWindow = state.mainWindowTemplate
    mainWindow.uuid = UUID().uuidString
    mainWindow.root = state.root
    mainWindow.isDirty = false
    mainWindow.htmlPreview = HtmlPreviewState(
      htmlFile: nil,
      server: Marked(self.baseServerUrl.appendingPathComponent(HtmlPreviewToolReducer.selectFirstPath))
    )

    mainWindow.urlsToOpen = urls.toDict { url in MainWindow.OpenMode.default }

    mainWindow.cwd = cwd

    mainWindow.preview.server = self.baseServerUrl.appendingPathComponent(MarkdownReducer.nonePath)

    return mainWindow
  }
}
