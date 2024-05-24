//
//  AppDelegate.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

// 导入Cocoa框架
import Cocoa

// AppDelegate类，遵循NSApplicationDelegate协议，是应用程序的委托对象
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // IBOutlet属性，连接到XIB或Storyboard文件中的UI元素
    // swiftlint:disable private_outlet
    @IBOutlet weak var openFolderMenuItem: NSMenuItem!
    @IBOutlet weak var reloadMenuItem: NSMenuItem!
    // swiftlint:enable private_outlet

    // 私有属性，获取当前编辑器窗口
    private var editorWindow: NSWindow? {
        return NSApp.windows.first(where: { $0.windowController is WindowController })
    }

    // 应用程序已成功启动后调用
    func applicationDidFinishLaunching(_: Notification) {}

    // 应用程序将要终止时调用
    func applicationWillTerminate(_: Notification) {}

    // 应用程序打开未命名文件时调用，返回true表示已成功打开
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showEditorWindow()
        return true
    }

    // 应用程序打开文件时调用，返回true表示已成功打开
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filename, isDirectory: &isDirectory),
              isDirectory.boolValue == true
        else {
            return false
        }
        showEditorWindow()
        let windowController = (editorWindow?.windowController) as! WindowController
        windowController.openFolder(withPath: filename)
        return true
    }

    // 私有方法，显示编辑器窗口
    private func showEditorWindow() {
        guard let editorWindow = editorWindow else {
            let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
            let editorWindowController = mainStoryboard.instantiateInitialController() as! WindowController
            editorWindowController.showWindow(self)
            return
        }
        editorWindow.makeKeyAndOrderFront(nil)
    }
}
