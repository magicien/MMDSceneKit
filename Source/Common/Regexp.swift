//
//  Regexp.swift
//
// http://qiita.com/tsuruchika/items/9ca9c4811e1f28b9417c
// http://easyramble.com/swift-regular-expression-utility.html
// http://www.raywenderlich.com/86205/nsregularexpression-swift-tutorial
//

import Foundation

class Regexp {
    let internalRegexp: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        do {
            self.internalRegexp = try NSRegularExpression(pattern: pattern, options: [])
        } catch let error as NSError {
            print(error.localizedDescription)
            self.internalRegexp = NSRegularExpression()
        }
    }
    
    func isMatch(_ input: String, startIndex: Int = 0, matchLength: Int = 100) -> Bool {
        let nsString = input as NSString
        let maxIndex = nsString.length
        
        var length = matchLength
        if startIndex + length > maxIndex {
            length = maxIndex - startIndex
        }

        let matches = self.internalRegexp.matches(in: input, options:[], range:NSMakeRange(startIndex, length))
        
        return matches.count > 0
    }
    
    func matches(_ input: String, startIndex: Int = 0, matchLength: Int = 100) -> [String]? {
        let nsString = input as NSString
        let maxIndex = nsString.length
        
        var length = matchLength
        if startIndex + length > maxIndex {
            length = maxIndex - startIndex
        }
        
        let matches = self.internalRegexp.matches( in: input, options: [], range:NSMakeRange(startIndex, length) )
        var results: [String] = []

        if matches.count == 0 {
            return nil
        }
        
        for match in matches {
            let rangeCount = match.numberOfRanges
            
            for group in 0..<rangeCount {
                let range = match.range(at: group)
                if range.length > 0 {
                    results.append(nsString.substring(with: range))
                }
            }
        }
        return results
    }
    
    func delMatches(_ input:String) -> String {
        var strRet:String = input
        if self.isMatch(input) {
            let matchList = self.matches(input)
            for i in 0 ..< matchList!.count {
                strRet = strRet.replacingOccurrences(of: matchList![i], with: "", options: [], range: nil)
            }
        }
        return strRet
    }
}

