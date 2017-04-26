//
//  HealthKitDataLoader.swift
//  Prancercise Tracker Starter
//
//  Created by Theodore Bendixson on 4/24/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import HealthKit

struct UserHealthProfile {
  var age: Int
  var biologicalSex: HKBiologicalSex
  var bloodType: HKBloodType
}

class ProfileDataStore {

  class func  getUserHealthProfile() throws -> UserHealthProfile {
    
    let healthKitStore = HKHealthStore()
    
    do {
      let birthdayComponents =  try healthKitStore.dateOfBirthComponents()
      let biologicalSex =       try healthKitStore.biologicalSex()
      let bloodType =           try healthKitStore.bloodType()
      
      let today = Date()
      let calendar = Calendar.current
      let todayDateComponents = calendar.dateComponents([.year],
                                                        from: today)
      let thisYear = todayDateComponents.year!
      let age = thisYear - birthdayComponents.year!
      
      return UserHealthProfile(age: age,
                               biologicalSex: biologicalSex.biologicalSex,
                               bloodType: bloodType.bloodType)
    }
  }
}

