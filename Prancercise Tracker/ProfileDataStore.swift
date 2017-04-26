//
//  HealthKitDataLoader.swift
//  Prancercise Tracker Starter
//
//  Created by Theodore Bendixson on 4/24/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import HealthKit

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
  
  class func getMostRecent(SampleType sampleType: HKSampleType,
                           completion: @escaping (HKSample?, Error?) -> Swift.Void) {
    
    let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date(),
                                                          end: Date.distantPast,
                                                          options: .strictEndDate)
    
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                          ascending: false)
    
    let limit = 1
    
    let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                    predicate: mostRecentPredicate,
                                    limit: limit,
                                    sortDescriptors: [sortDescriptor]) { (query, samples, error) in
    
      DispatchQueue.main.async {
        guard let samples = samples,
          let mostRecentSample = samples.first as? HKQuantitySample else {
            
            if let error = error {
              completion(nil, error)
              return
            }
            
            completion(nil, nil)
            return
        }
        completion(mostRecentSample, nil)
      }
    }
    
    HKHealthStore().execute(sampleQuery)
  }
  
  class func saveBodyMassIndexSample(bodyMassIndex: Double, date: Date) {
    
    guard let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
      fatalError("Body Mass Index Type is no longer available in HealthKit")
    }
    
    let bodyMassQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: bodyMassIndex)
    
    let bodyMassIndexSample = HKQuantitySample(type: bodyMassIndexType,
                                               quantity: bodyMassQuantity,
                                               start: date,
                                               end: date)
    
    HKHealthStore().save(bodyMassIndexSample) { (success, error) in
      
      if let error = error {
        print("Error Saving BMI Sample: \(error.localizedDescription)")
      } else {
        print("Successfully save BMI Sample")
      }
      
    }
  }
  
}

