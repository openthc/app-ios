//
//  Platform.swift
//  OpenTHC
//
//  Created by Theodore Newell on 4/29/17.
//  Copyright © 2017 OpenTHC. All rights reserved.
//

import Foundation

/// - Author: Justin Driscoll, http://themainthread.com/blog/2015/06/simulator-check-in-swift.html
struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}
