//
//  Preferences.swift
//  Created by Michael Simms on 6/14/23.
//

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
