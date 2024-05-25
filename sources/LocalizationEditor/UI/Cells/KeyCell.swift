//
//  KeyCell.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

// 导入Cocoa和Foundation框架
import Cocoa
import Foundation

// 定义KeyCell类，继承NSTableCellView类
final class KeyCell: NSTableCellView {
   // MARK: - Outlets

   // 私有弱引用Outlets，连接到 storyboard 中的 NSTextField 视图
   @IBOutlet private weak var keyLabel: NSTextField!
   @IBOutlet private weak var messageLabel: NSTextField!

   // MARK: - Properties

   // 类属性 identifier，用于标识 KeyCell 的唯一标识符
   static let identifier = "KeyCell"

   // 属性 key，用于存储键值，设置 key 值时，会同步更新 keyLabel 的字符串值
   var key: String? {
       didSet {
           keyLabel.stringValue = key ?? ""
       }
   }

   // 属性 message，用于存储消息，设置 message 值时，会同步更新 messageLabel 的字符串值
   var message: String? {
       didSet {
           messageLabel.stringValue = message ?? ""
       }
   }
}
