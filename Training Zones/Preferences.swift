//
//  Preferences.swift
//  Created by Michael Simms on 6/14/23.
//

//	MIT License
//
//  Copyright © 2023 Michael J Simms. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.

import Foundation

let PREF_NAME_UNITS =    "Units"
let PREF_NAME_METRIC =   "Metric"
let PREF_NAME_IMPERIAL = "Imperial"

class Preferences {
	
	//
	// Get methods
	//
	
	static func preferredUnitSystem() -> String {
		let mydefaults: UserDefaults = UserDefaults.standard
		let str = mydefaults.string(forKey: PREF_NAME_UNITS)
		
		if str != nil {
			return str!
		}
		return PREF_NAME_METRIC
	}
	
	//
	// Set methods
	//
	
	static func setPreferredUnitSystem(system: String) {
		let mydefaults: UserDefaults = UserDefaults.standard
		mydefaults.set(system, forKey: PREF_NAME_UNITS)
	}
}
