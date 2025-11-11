//
//  VO2MaxCalculator.swift
//  Created by Michael Simms on 5/25/23.
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

class VO2MaxCalculator {
	func EstimateVO2MaxUsingCooperTestMetric(kms: Double) -> Double {
		return (22.351 * kms) - 11.288
	}

	func EstimateVO2MaxUsingCooperTestImperial(miles: Double) -> Double {
		return (25.97 * miles) - 11.29
	}

	func EstimateVO2MaxFromHeartRate(maxHR: Double, restingHR: Double) -> Double {
		return 15.3 * (maxHR / restingHR)
	}

	/// @brief Daniels and Gilbert VO2 Max formula
	func EstimateVO2MaxFromRaceDistanceInMeters(raceDistanceMeters: Double, raceTimeSecs: Double) -> Double {
		let t = raceTimeSecs / 60
		let v = raceDistanceMeters / t
		return (-4.60 + 0.182258 * v + 0.000104 * pow(v, 2.0)) / (0.8 + 0.1894393 * pow(exp(1), -0.012778 * t) + 0.2989558 * pow(exp(1), -0.1932605 * t))
	}

	func EstimateVO2MaxFromRaceDistanceInMetersAndHeartRate(raceDistanceMeters: Double, raceTimeMinutes: Double, loadHr: Double, restingHr: Double, maxHr: Double) -> Double {
		return (raceDistanceMeters / raceTimeMinutes * 0.2) / ((loadHr - restingHr) / (maxHr - restingHr)) + 3.5
	}
}
