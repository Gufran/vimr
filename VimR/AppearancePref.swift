/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import PureLayout
import RxSwift

class AppearancePref: PrefPane, NSComboBoxDelegate, NSControlTextEditingDelegate {

  typealias StateType = AppState

  enum Action {

    case setUsesLigatures(Bool)
    case setFont(NSFont)
    case setLinespacing(CGFloat)
  }

  override var displayName: String {
    return "Appearance"
  }

  override var pinToContainer: Bool {
    return true
  }

  override func windowWillClose() {
    self.linespacingAction()
  }

  required init(source: Observable<StateType>, emitter: ActionEmitter, state: StateType) {
    self.emit = emitter.typedEmit()

    self.font = state.mainWindowTemplate.appearance.font
    self.linespacing = state.mainWindowTemplate.appearance.linespacing
    self.usesLigatures = state.mainWindowTemplate.appearance.usesLigatures

    super.init(frame: .zero)

    self.addViews()
    self.updateViews()

    source
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { state in
        let appearance = state.mainWindowTemplate.appearance

        if self.font != appearance.font
           || self.linespacing != appearance.linespacing
           || self.usesLigatures != appearance.usesLigatures {
          self.font = appearance.font
          self.linespacing = appearance.linespacing
          self.usesLigatures = appearance.usesLigatures

          self.updateViews()
        }
      })
      .disposed(by: self.disposeBag)
  }

  fileprivate let emit: (Action) -> Void
  fileprivate let disposeBag = DisposeBag()

  fileprivate let fontManager = NSFontManager.shared()

  fileprivate var font: NSFont
  fileprivate var linespacing: CGFloat
  fileprivate var usesLigatures: Bool

  fileprivate let sizes = [9, 10, 11, 12, 13, 14, 16, 18, 24, 36, 48, 64]
  fileprivate let sizeCombo = NSComboBox(forAutoLayout: ())
  fileprivate let fontPopup = NSPopUpButton(frame: CGRect.zero, pullsDown: false)
  fileprivate let linespacingField = NSTextField(forAutoLayout: ())
  fileprivate let ligatureCheckbox = NSButton(forAutoLayout: ())
  fileprivate let previewArea = NSTextView(frame: CGRect.zero)

  fileprivate let exampleText =
    "abcdefghijklmnopqrstuvwxyz\n" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n" +
    "0123456789\n" +
    "(){}[] +-*/= .,;:!?#&$%@|^\n" +
    "<- -> => >> << >>= =<< .. \n" +
    ":: -< >- -<< >>- ++ /= =="

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func addViews() {
    let paneTitle = self.paneTitleTextField(title: "Appearance")

    let fontTitle = self.titleTextField(title: "Default Font:")

    let fontPopup = self.fontPopup
    fontPopup.translatesAutoresizingMaskIntoConstraints = false
    fontPopup.target = self
    fontPopup.action = #selector(AppearancePref.fontPopupAction)

    // This takes approx. 0.8s - 1s on my machine... -_-
    DispatchQueue.global(qos: .background).async {
      fontPopup.addItems(withTitles: self.fontManager.availableFontNames(with: .fixedPitchFontMask)!)
    }

    let sizeCombo = self.sizeCombo
    sizeCombo.delegate = self
    sizeCombo.target = self
    sizeCombo.action = #selector(AppearancePref.sizeComboBoxDidEnter(_:))
    self.sizes.forEach { string in
      sizeCombo.addItem(withObjectValue: string)
    }

    let linespacingTitle = self.titleTextField(title: "Line Spacing:")
    let linespacingField = self.linespacingField

    let ligatureCheckbox = self.ligatureCheckbox
    self.configureCheckbox(button: ligatureCheckbox,
                           title: "Use Ligatures",
                           action: #selector(AppearancePref.usesLigaturesAction(_:)))

    let previewArea = self.previewArea
    previewArea.isEditable = true
    previewArea.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    previewArea.isVerticallyResizable = true
    previewArea.isHorizontallyResizable = true
    previewArea.textContainer?.heightTracksTextView = false
    previewArea.textContainer?.widthTracksTextView = false
    previewArea.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
    previewArea.textContainer?.containerSize = CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    previewArea.layoutManager?.replaceTextStorage(NSTextStorage(string: self.exampleText))
    previewArea.isRichText = false
    previewArea.turnOffLigatures(self)

    let previewScrollView = NSScrollView(forAutoLayout: ())
    previewScrollView.hasVerticalScroller = true
    previewScrollView.hasHorizontalScroller = true
    previewScrollView.autohidesScrollers = true
    previewScrollView.borderType = .bezelBorder
    previewScrollView.documentView = previewArea

    self.addSubview(paneTitle)

    self.addSubview(fontTitle)
    self.addSubview(fontPopup)
    self.addSubview(sizeCombo)
    self.addSubview(linespacingTitle)
    self.addSubview(linespacingField)
    self.addSubview(ligatureCheckbox)
    self.addSubview(previewScrollView)

    paneTitle.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
    paneTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

    fontTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18, relation: .greaterThanOrEqual)
    fontTitle.autoAlignAxis(.baseline, toSameAxisOf: fontPopup)

    fontPopup.autoPinEdge(.top, to: .bottom, of: paneTitle, withOffset: 18)
    fontPopup.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)
    fontPopup.autoSetDimension(.width, toSize: 240)

    sizeCombo.autoSetDimension(.width, toSize: 60)
    // If we use .Baseline the combo box is placed one pixel off...
    sizeCombo.autoAlignAxis(.horizontal, toSameAxisOf: fontPopup)
    sizeCombo.autoPinEdge(.left, to: .right, of: fontPopup, withOffset: 5)

    linespacingTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 18, relation: .greaterThanOrEqual)
    linespacingTitle.autoPinEdge(.right, to: .right, of: fontTitle)
    linespacingTitle.autoAlignAxis(.baseline, toSameAxisOf: linespacingField)

    linespacingField.autoPinEdge(.top, to: .bottom, of: sizeCombo, withOffset: 18)
    linespacingField.autoPinEdge(.left, to: .right, of: linespacingTitle, withOffset: 5)
    linespacingField.autoSetDimension(.width, toSize: 60)
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSControlTextDidEndEditing,
                                           object: linespacingField,
                                           queue: nil) { [unowned self] _ in
      self.linespacingAction()
    }

    ligatureCheckbox.autoPinEdge(.top, to: .bottom, of: linespacingField, withOffset: 18)
    ligatureCheckbox.autoPinEdge(.left, to: .right, of: fontTitle, withOffset: 5)

    previewScrollView.autoSetDimension(.height, toSize: 200, relation: .greaterThanOrEqual)
    previewScrollView.autoPinEdge(.top, to: .bottom, of: ligatureCheckbox, withOffset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
    previewScrollView.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
  }

  fileprivate func updateViews() {
    self.fontPopup.selectItem(withTitle: self.font.fontName)
    self.sizeCombo.stringValue = String(Int(self.font.pointSize))
    self.linespacingField.stringValue = String(format: "%.2f", self.linespacing)
    self.ligatureCheckbox.boolState = self.usesLigatures
    self.previewArea.font = self.font

    if self.usesLigatures {
      self.previewArea.useAllLigatures(self)
    } else {
      self.previewArea.turnOffLigatures(self)
    }
  }
}

// MARK: - Actions
extension AppearancePref {

  func usesLigaturesAction(_ sender: NSButton) {
    self.emit(.setUsesLigatures(sender.boolState))
  }

  func fontPopupAction(_ sender: NSPopUpButton) {
    guard let selectedItem = self.fontPopup.selectedItem else {
      return
    }

    guard selectedItem.title != self.font.fontName else {
      return
    }

    guard let newFont = NSFont(name: selectedItem.title, size: self.font.pointSize) else {
      return
    }

    self.emit(.setFont(newFont))
  }

  func comboBoxSelectionDidChange(_ notification: Notification) {
    guard (notification.object as! NSComboBox) === self.sizeCombo else {
      return
    }

    let newFontSize = self.cappedFontSize(Int(self.sizes[self.sizeCombo.indexOfSelectedItem]))
    let newFont = self.fontManager.convert(self.font, toSize: newFontSize)

    self.emit(.setFont(newFont))
  }

  func sizeComboBoxDidEnter(_ sender: AnyObject!) {
    let newFontSize = self.cappedFontSize(self.sizeCombo.integerValue)
    let newFont = self.fontManager.convert(self.font, toSize: newFontSize)

    self.emit(.setFont(newFont))
  }

  func linespacingAction() {
    let newLinespacing = self.cappedLinespacing(self.linespacingField.floatValue)
    self.emit(.setLinespacing(newLinespacing))
  }

  fileprivate func cappedLinespacing(_ linespacing: Float) -> CGFloat {
    let cgfLinespacing = CGFloat(linespacing)

    guard cgfLinespacing >= NeoVimView.minLinespacing else {
      return NeoVimView.defaultLinespacing
    }

    guard cgfLinespacing <= NeoVimView.maxLinespacing else {
      return NeoVimView.maxLinespacing
    }

    return cgfLinespacing
  }

  fileprivate func cappedFontSize(_ size: Int) -> CGFloat {
    let cgfSize = CGFloat(size)

    guard cgfSize >= NeoVimView.minFontSize else {
      return NeoVimView.defaultFont.pointSize
    }

    guard cgfSize <= NeoVimView.maxFontSize else {
      return NeoVimView.maxFontSize
    }

    return cgfSize
  }
}
