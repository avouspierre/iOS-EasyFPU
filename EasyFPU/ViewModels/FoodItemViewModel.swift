//
//  FoodItemViewModel.swift
//  EasyFPU
//
//  Created by Ulrich Rüth on 24.07.20.
//  Copyright © 2020 Ulrich Rüth. All rights reserved.
//

import Foundation

enum FoodItemViewModelError {
    case name(String), calories(String), carbs(String), sugars(String), amount(String), tooMuchCarbs(String), tooMuchSugars(String), fat(String),proteins(String)
}

enum FoodItemCategory: String {
    case product = "Product"
    case ingredient = "Ingredient"
}

class FoodItemViewModel: ObservableObject, Codable, Hashable, Identifiable, VariableAmountItem {
    var id: UUID? {
        // We reuse the id of the Core Data FoodItem - or return nil
        cdFoodItem?.id
    }
    
    @Published var name: String
    @Published var favorite: Bool
    @Published var caloriesPer100gAsString: String = "" {
        willSet {
            let result = DataHelper.checkForPositiveDouble(valueAsString: newValue, allowZero: true)
            switch result {
            case .success(let caloriesAsDouble):
                caloriesPer100g = caloriesAsDouble
            case .failure(let err):
                debugPrint(err.evaluate())
                return
            }
        }
    }
    @Published var carbsPer100gAsString: String = "" {
        willSet {
            let result = DataHelper.checkForPositiveDouble(valueAsString: newValue, allowZero: true)
            switch result {
            case .success(let carbsAsDouble):
                carbsPer100g = carbsAsDouble
            case .failure(let err):
                debugPrint(err.evaluate())
                return
            }
        }
    }
    @Published var sugarsPer100gAsString: String = "" {
        willSet {
            let result = DataHelper.checkForPositiveDouble(valueAsString: newValue, allowZero: true)
            switch result {
            case .success(let sugarsAsDouble):
                sugarsPer100g = sugarsAsDouble
            case .failure(let err):
                debugPrint(err.evaluate())
                return
            }
        }
    }
    @Published var amountAsString: String = "" {
        willSet {
            let result = DataHelper.checkForPositiveInt(valueAsString: newValue, allowZero: true)
            switch result {
            case .success(let amountAsInt):
                amount = amountAsInt
            case .failure(let err):
                debugPrint(err.evaluate())
                return
            }
        }
    }
    @Published var fatPer100gAsString: String = "" {
        willSet {
            let result = DataHelper.checkForPositiveDouble(valueAsString: newValue, allowZero: true)
            switch result {
            case .success(let fatAsDouble):
                fatPer100g = fatAsDouble
            case .failure(let err):
                debugPrint(err.evaluate())
                return
            }
        }
    }
    @Published var proteinsPer100gAsString: String = "" {
        willSet {
            let result = DataHelper.checkForPositiveDouble(valueAsString: newValue, allowZero: true)
            switch result {
            case .success(let proteinsAsDouble):
                proteinsPer100g = proteinsAsDouble
            case .failure(let err):
                debugPrint(err.evaluate())
                return
            }
        }
    }
    @Published var category: FoodItemCategory
    private(set) var caloriesPer100g: Double = 0.0
    private(set) var carbsPer100g: Double = 0.0
    private(set) var sugarsPer100g: Double = 0.0
    private(set) var fatPer100g: Double = 0.0
    private(set) var proteinsPer100g: Double = 0.0
    @Published var amount: Int = 0
    @Published var typicalAmounts = [TypicalAmountViewModel]()
    var cdFoodItem: FoodItem?
    var cdComposedFoodItem: ComposedFoodItem?
    
    enum CodingKeys: String, CodingKey {
        case foodItem
        case amount, caloriesPer100g, carbsPer100g, sugarsPer100g, favorite, name, typicalAmounts, category,fatPer100g,proteinsPer100g
        case composedFoodItem
    }
    
    init(name: String, category: FoodItemCategory, favorite: Bool, caloriesPer100g: Double, carbsPer100g: Double, sugarsPer100g: Double, amount: Int,fatPer100g:Double,proteinsPer100g:Double) {
        self.name = name
        self.category = category
        self.favorite = favorite
        self.caloriesPer100g = caloriesPer100g
        self.carbsPer100g = carbsPer100g
        self.sugarsPer100g = sugarsPer100g
        self.fatPer100g = fatPer100g
        self.proteinsPer100g = proteinsPer100g
        self.amount = amount
        
        initStringRepresentations(amount: amount, carbsPer100g: carbsPer100g, caloriesPer100g: caloriesPer100g, sugarsPer100g: sugarsPer100g,fatPer100g: fatPer100g,proteinsPer100g:proteinsPer100g)
    }
    
    init(from cdFoodItem: FoodItem) {
        self.name = cdFoodItem.name ?? NSLocalizedString("- Unnamned -", comment: "")
        self.category = FoodItemCategory.init(rawValue: cdFoodItem.category ?? FoodItemCategory.product.rawValue) ?? FoodItemCategory.product // Default is product
        self.favorite = cdFoodItem.favorite
        self.caloriesPer100g = cdFoodItem.caloriesPer100g
        self.carbsPer100g = cdFoodItem.carbsPer100g
        self.sugarsPer100g = cdFoodItem.sugarsPer100g
        self.fatPer100g = cdFoodItem.fatPer100g
        self.proteinsPer100g = cdFoodItem.proteinsPer100g
        self.cdFoodItem = cdFoodItem
        if let cdComposedFoodItem = cdFoodItem.composedFoodItem {
            self.cdComposedFoodItem = cdComposedFoodItem
        }
        
        initStringRepresentations(amount: amount, carbsPer100g: carbsPer100g, caloriesPer100g: caloriesPer100g, sugarsPer100g: sugarsPer100g,fatPer100g: fatPer100g,proteinsPer100g:proteinsPer100g)
        
        if cdFoodItem.typicalAmounts != nil {
            for typicalAmount in cdFoodItem.typicalAmounts!.allObjects {
                let castedTypicalAmount = typicalAmount as! TypicalAmount
                typicalAmounts.append(TypicalAmountViewModel(from: castedTypicalAmount))
            }
        }
    }
    
    init(from cdIngredient: Ingredient) {
        self.name = cdIngredient.name ?? NSLocalizedString("- Unnamned -", comment: "")
        self.category = FoodItemCategory.init(rawValue: cdIngredient.category ?? FoodItemCategory.product.rawValue) ?? FoodItemCategory.product // Default is product
        self.favorite = cdIngredient.favorite
        self.caloriesPer100g = cdIngredient.caloriesPer100g
        self.carbsPer100g = cdIngredient.carbsPer100g
        self.sugarsPer100g = cdIngredient.sugarsPer100g
        self.fatPer100g = cdIngredient.fatPer100g
        self.proteinsPer100g = cdIngredient.proteinsPer100g
        self.amount = Int(cdIngredient.amount)
        self.cdFoodItem = cdIngredient.foodItem
        
        initStringRepresentations(amount: amount, carbsPer100g: carbsPer100g, caloriesPer100g: caloriesPer100g, sugarsPer100g: sugarsPer100g,fatPer100g: fatPer100g,proteinsPer100g:proteinsPer100g)
    }
    
    init?(name: String, category: FoodItemCategory, favorite: Bool, caloriesAsString: String, carbsAsString: String, sugarsAsString: String, amountAsString: String, fatAsString: String, proteinsAsString: String, error: inout FoodItemViewModelError) {
        // Check for a correct name
        let foodName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if foodName == "" {
            error = .name(NSLocalizedString("Name must not be empty", comment: ""))
            return nil
        } else {
            self.name = foodName
        }
        
        // Set category
        self.category = category
        
        // Set favorite
        self.favorite = favorite
        
        // Check for valid calories
        let caloriesResult = DataHelper.checkForPositiveDouble(valueAsString: caloriesAsString == "" ? "0" : caloriesAsString, allowZero: true)
        switch caloriesResult {
        case .success(let caloriesAsDouble):
            caloriesPer100g = caloriesAsDouble
        case .failure(let err):
            let errorMessage = err.evaluate()
            error = .calories(errorMessage)
            return nil
        }
        self.caloriesPer100gAsString = caloriesAsString
        
        // Check for valid carbs
        let carbsResult = DataHelper.checkForPositiveDouble(valueAsString: carbsAsString == "" ? "0" : carbsAsString, allowZero: true)
        switch carbsResult {
        case .success(let carbsAsDouble):
            carbsPer100g = carbsAsDouble
        case .failure(let err):
            let errorMessage = err.evaluate()
            error = .carbs(errorMessage)
            return nil
        }
        self.carbsPer100gAsString = carbsAsString
        
        // Check for valid sugars
        let sugarsResult = DataHelper.checkForPositiveDouble(valueAsString: sugarsAsString == "" ? "0" : sugarsAsString, allowZero: true)
        switch sugarsResult {
        case .success(let sugarsAsDouble):
            sugarsPer100g = sugarsAsDouble
        case .failure(let err):
            let errorMessage = err.evaluate()
            error = .sugars(errorMessage)
            return nil
        }
        self.sugarsPer100gAsString = sugarsAsString
        
        let fatResult = DataHelper.checkForPositiveDouble(valueAsString: fatAsString == "" ? "0" : fatAsString, allowZero: true)
        switch fatResult {
        case .success(let fatAsDouble):
            fatPer100g = fatAsDouble
        case .failure(let err):
            let errorMessage = err.evaluate()
            error = .fat(errorMessage)
            return nil
        }
        self.fatPer100gAsString = fatAsString
        
        let proteinsResult = DataHelper.checkForPositiveDouble(valueAsString: proteinsAsString == "" ? "0" : proteinsAsString, allowZero: true)
        switch proteinsResult {
        case .success(let proteinsAsDouble):
            proteinsPer100g = proteinsAsDouble
        case .failure(let err):
            let errorMessage = err.evaluate()
            error = .proteins(errorMessage)
            return nil
        }
        self.proteinsPer100gAsString = proteinsAsString
        
        // Check if sugars exceed carbs
        if sugarsPer100g > carbsPer100g {
            error = .tooMuchSugars(NSLocalizedString("Sugars exceed carbs", comment: ""))
            return nil
        }
        
        // Check if calories from carbs exceed total calories
        if carbsPer100g * 4 > caloriesPer100g {
            error = .tooMuchCarbs(NSLocalizedString("Calories from carbs (4 kcal per gram) exceed total calories", comment: ""))
            return nil
        }
        
        // Check for valid amount
        let amountResult = DataHelper.checkForPositiveInt(valueAsString: amountAsString == "" ? "0" : amountAsString, allowZero: true)
        switch amountResult {
        case .success(let amountAsInt):
            amount = amountAsInt
        case .failure(let err):
            let errorMessage = err.evaluate()
            error = .amount(errorMessage)
            return nil
        }
        self.amountAsString = amountAsString
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let foodItem = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .foodItem)
        category = try FoodItemCategory.init(rawValue: foodItem.decode(String.self, forKey: .category)) ?? .product
        amount = try foodItem.decode(Int.self, forKey: .amount)
        caloriesPer100g = try foodItem.decode(Double.self, forKey: .caloriesPer100g)
        carbsPer100g = try foodItem.decode(Double.self, forKey: .carbsPer100g)
        sugarsPer100g = try foodItem.decode(Double.self, forKey: .sugarsPer100g)
        fatPer100g = try foodItem.decode(Double.self, forKey: .fatPer100g)
        proteinsPer100g = try foodItem.decode(Double.self, forKey: .proteinsPer100g)
        favorite = try foodItem.decode(Bool.self, forKey: .favorite)
        name = try foodItem.decode(String.self, forKey: .name)
        typicalAmounts = try foodItem.decode([TypicalAmountViewModel].self, forKey: .typicalAmounts)
        
        guard
            let caloriesAsString = DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: caloriesPer100g)),
            let carbsAsString = DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: carbsPer100g)),
            let sugarsAsString = DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: sugarsPer100g)),
            let amountAsString = DataHelper.intFormatter.string(from: NSNumber(value: amount)),
            let fatAsString = DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: fatPer100g)),
            let proteinsAsString = DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: proteinsPer100g))
        else {
            throw InvalidNumberError.inputError(NSLocalizedString("Fatal error: Cannot convert numbers into string, please contact app developer", comment: ""))
        }
        self.caloriesPer100gAsString = caloriesAsString
        self.carbsPer100gAsString = carbsAsString
        self.sugarsPer100gAsString = sugarsAsString
        self.amountAsString = amountAsString
        self.proteinsPer100gAsString = proteinsAsString
        self.fatPer100gAsString = fatAsString
        
        if let composedFoodItemVM = try? foodItem.decode(ComposedFoodItemViewModel.self, forKey: .composedFoodItem) {
            self.cdComposedFoodItem = ComposedFoodItem.create(from: composedFoodItemVM)
        }
    }
    
    private func initStringRepresentations(amount: Int, carbsPer100g: Double, caloriesPer100g: Double, sugarsPer100g: Double,fatPer100g: Double,proteinsPer100g: Double) {
        self.caloriesPer100gAsString = caloriesPer100g == 0 ? "" : DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: caloriesPer100g))!
        self.carbsPer100gAsString = carbsPer100g == 0 ? "" : DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: carbsPer100g))!
        self.sugarsPer100gAsString = sugarsPer100g == 0 ? "" : DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: sugarsPer100g))!
        self.amountAsString = amount == 0 ? "" : DataHelper.intFormatter.string(from: NSNumber(value: amount))!
        self.fatPer100gAsString = fatPer100g == 0 ? "" : DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: fatPer100g))!
        self.proteinsPer100gAsString = proteinsPer100g == 0 ? "" : DataHelper.doubleFormatter(numberOfDigits: 5).string(from: NSNumber(value: proteinsPer100g))!
    }
    
    func fill(with foodDatabaseEntry: FoodDatabaseEntry) {
        name = foodDatabaseEntry.name
        category = foodDatabaseEntry.category
        
        // When setting string representations, number will be set implicitely
        caloriesPer100gAsString = DataHelper.doubleFormatter(numberOfDigits: 1).string(from: NSNumber(value: foodDatabaseEntry.caloriesPer100g.getEnergyInKcal()))!
        carbsPer100gAsString = DataHelper.doubleFormatter(numberOfDigits: 1).string(from: NSNumber(value: foodDatabaseEntry.carbsPer100g))!
        sugarsPer100gAsString = DataHelper.doubleFormatter(numberOfDigits: 1).string(from: NSNumber(value: foodDatabaseEntry.sugarsPer100g))!
        fatPer100gAsString = DataHelper.doubleFormatter(numberOfDigits: 1).string(from: NSNumber(value: foodDatabaseEntry.fatPer100g))!
        proteinsPer100gAsString = DataHelper.doubleFormatter(numberOfDigits: 1).string(from: NSNumber(value: foodDatabaseEntry.proteinsPer100g))!
    }
    
    func getCalories() -> Double {
        Double(self.amount) / 100 * self.caloriesPer100g
    }
    
    func getCarbsInclSugars() -> Double {
        Double(self.amount) / 100 * self.carbsPer100g
    }
    
    func getSugarsOnly() -> Double {
        Double(self.amount) / 100 * self.sugarsPer100g
    }
    
    func getFatOnly() -> Double {
        Double(self.amount) / 100 * self.fatPer100g
    }
    
    func getProteinssOnly() -> Double {
        Double(self.amount) / 100 * self.proteinsPer100g
    }
    
    func getRegularCarbs(when treatSugarsSeparately: Bool) -> Double {
        Double(self.amount) / 100 * (treatSugarsSeparately ? (self.carbsPer100g - self.sugarsPer100g) : self.carbsPer100g)
    }
    
    func getSugars(when treatSugarsSeparately: Bool) -> Double {
        Double(self.amount) / 100 * (treatSugarsSeparately ? self.sugarsPer100g : 0)
    }
    
    func getFPU() -> FPU {
        // 1g carbs has ~4 kcal, so calculate carb portion of calories
        let carbsCal = Double(self.amount) / 100 * self.carbsPer100g * 4;

        // The carbs from fat and protein is the remainder
        let calFromFP = getCalories() - carbsCal;

        // 100kcal makes 1 FPU
        let fpus = calFromFP / 100;

        // Create and return the FPU object
        return FPU(fpu: fpus)
    }
    
    func changeCategory(to newCategory: FoodItemCategory) {
        if category != newCategory {
            category = newCategory
            FoodItem.setCategory(cdFoodItem, to: newCategory.rawValue)
        }
    }
    
    func duplicate() {
        let nameOfDuplicate = "\(name) - \(NSLocalizedString("Copy", comment: ""))"
        let duplicate = FoodItemViewModel(
            name: nameOfDuplicate,
            category: category,
            favorite: favorite,
            caloriesPer100g: caloriesPer100g,
            carbsPer100g: carbsPer100g,
            sugarsPer100g: sugarsPer100g,
            amount: 0,
            fatPer100g: fatPer100g,
            proteinsPer100g: proteinsPer100g
        )
        duplicate.typicalAmounts = typicalAmounts
        
        // Check if this was associated to a ComposedFoodItem
        if let cdComposedFoodItem = cdComposedFoodItem {
            duplicate.cdComposedFoodItem = ComposedFoodItem.create(from: cdComposedFoodItem)
            duplicate.cdComposedFoodItem?.name = nameOfDuplicate
        }
        
        // Create new FoodItem in CoreData
        duplicate.cdFoodItem = FoodItem.create(from: duplicate)
    }
    
    func exportToURL() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let encoded = try? encoder.encode(self) else { return nil }
        
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let path = documents?.appendingPathComponent("/\(name).fooditem") else {
            return nil
        }
        
        do {
            try encoded.write(to: path, options: .atomicWrite)
            return path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var foodItem = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .foodItem)
        try foodItem.encode(category.rawValue, forKey: .category)
        try foodItem.encode(amount, forKey: .amount)
        try foodItem.encode(caloriesPer100g, forKey: .caloriesPer100g)
        try foodItem.encode(carbsPer100g, forKey: .carbsPer100g)
        try foodItem.encode(sugarsPer100g, forKey: .sugarsPer100g)
        try foodItem.encode(favorite, forKey: .favorite)
        try foodItem.encode(name, forKey: .name)
        try foodItem.encode(typicalAmounts, forKey: .typicalAmounts)
        try foodItem.encode(fatPer100g, forKey: .fatPer100g)
        try foodItem.encode(proteinsPer100g, forKey: .proteinsPer100g)
        
        if let cdComposedFoodItem = cdComposedFoodItem {
            let composedFoodItemVM = ComposedFoodItemViewModel(
                name: cdComposedFoodItem.name ?? NSLocalizedString("- Unnamed -", comment: ""),
                category: FoodItemCategory.init(rawValue: cdComposedFoodItem.category ?? FoodItemCategory.product.rawValue) ?? .product,
                favorite: cdComposedFoodItem.favorite
            )
            
            composedFoodItemVM.fill(from: cdComposedFoodItem, syncStrategy: .createMissingFoodItems)
            
            try foodItem.encode(composedFoodItemVM, forKey: .composedFoodItem)
        }
    }
    
    static func == (lhs: FoodItemViewModel, rhs: FoodItemViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
