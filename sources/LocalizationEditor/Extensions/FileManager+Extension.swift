//
//  FileManager+Extension.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 01/02/2019.
//  Copyright © 2019 Igor Kulman. All rights reserved.
//

import Foundation

// Swift 拓展（Extension）用于在不创建新类型的情况下给已有类型（如 FileManager）添加新功能。
extension FileManager {
    // 递归获取 URL 下的所有文件，返回一个 URL 数组。
    // - Parameter url: 需要查找的 URL。
    // - Returns: URL 数组。
    func getAllFilesRecursively(url: URL) -> [URL] {
        // 获取 enumerator，用于遍历 URL 下的所有条目。
        guard let enumerator = FileManager.default.enumerator(atPath: url.path) else {
            // 如果 enumerator 创建失败，返回一个空数组。
            return []
        }

        // 使用 enumerator 遍历 URL 下的所有条目，并将符合条件的条目转换为 URL，最终返回一个 URL 数组。
        // - Returns: 条目对应的 URL，或 nil。
        return enumerator.compactMap({ element -> URL? in
            // 确保条目是字符串类型。
            guard let path = element as? String else {
                // 如果不是，返回 nil。
                return nil
            }

            // 返回条目对应的 URL。
            // - Parameter path: 条目路径。
            // - Parameter isDirectory: 条目是否是目录，false 表示文件。
            return url.appendingPathComponent(path, isDirectory: false)
        })
    }
}
