//
//  String+Extensions.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 05/02/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation

// extension String
//  在 Swift 中，扩展可以为现有类型添加新功能。这个文件中的代码为 String 类型添加了一些额外的功能。
//  添加了 slice(from:to:) 函数，可以从当前字符串中获取从 fromString 到 toString 之间的子字符串。
extension String {

    //  参数 fromString 和 toString 用于界定子字符串的范围，如果不存在这两个字符串，则返回 nil。
    func slice(from fromString: String, to toString: String) -> String? {

        //  获取 fromString 在当前字符串中的范围，并取其 upperBound（即 fromString 的结束位置）。
        return (range(of: fromString)?.upperBound).flatMap { substringFrom in

            //  从 substringFrom 的位置开始搜索 toString，找到 toString 后取其开始位置。
            (range(of: toString, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in

                //  截取 substringFrom 到 substringTo 之间的子字符串，并返回。
                String(self[substringFrom..<substringTo])
            }
        }
    }

    //  返回当前字符串，按照区域设置和大小写不敏感的方式进行规范化。
    var normalized: String {
        return folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    //  返回当前字符串，首字母大写，其余字母小写。
    var capitalizedFirstLetter: String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }

    //  将字符串中的转义字符转换为对应的字符。
    var unescaped: String {
        let entities = [
            "\\n": "\n",
            "\\t": "\t",
            "\\r": "\r",
            "\\\"": "\"",
            "\\'": "'",
            "\\\\": "\\"
        ]
        var current = self
        for (key, value) in entities {
            current = current.replacingOccurrences(of: key, with: value)
        }
        return current
    }

    //  将字符串中的双引号和换行符转换为转义字符。
    var escaped: String {
        return self.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
    }

    //  返回当前字符串的本地化版本，如果没有找到对应的本地化资源，则返回当前字符串本身。
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
