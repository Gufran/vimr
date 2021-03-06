/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Foundation

class UiRootReducer {

  typealias Pair = StateActionPair<AppState, UuidAction<MainWindow.Action>>

  func reduce(_ pair: Pair) -> Pair {
    var appState = pair.state
    let uuid = pair.action.uuid

    switch pair.action.payload {

    case .becomeKey:
      appState.currentMainWindowUuid = uuid
      appState.mainWindowTemplate = self.mainWindowTemplate(
        from: appState.mainWindowTemplate, new: appState.mainWindows[uuid] ?? appState.mainWindowTemplate
      )

    case .close:
      if appState.currentMainWindowUuid == uuid, let mainWindowToClose = appState.mainWindows[uuid] {
        appState.mainWindowTemplate = self.mainWindowTemplate(from: appState.mainWindowTemplate,
                                                              new: mainWindowToClose)

        appState.currentMainWindowUuid = nil
      }

      appState.mainWindows.removeValue(forKey: uuid)

    default:
      return pair

    }

    return StateActionPair(state: appState, action: pair.action)
  }
  
  fileprivate func mainWindowTemplate(from old: MainWindow.State, new: MainWindow.State) -> MainWindow.State {
    var result = old

    result.isAllToolsVisible = new.isAllToolsVisible
    result.isToolButtonsVisible = new.isToolButtonsVisible
    result.tools = new.tools
    result.previewTool = new.previewTool
    result.fileBrowserShowHidden = new.fileBrowserShowHidden
    result.htmlPreview = .default

    return result
  }
}
