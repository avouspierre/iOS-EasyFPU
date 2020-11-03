//
//  FoodItemListView.swift
//  EasyFPU
//
//  Created by Ulrich Rüth on 01.11.20.
//  Copyright © 2020 Ulrich Rüth. All rights reserved.
//

import SwiftUI

struct FoodItemListView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    private var category: FoodItemCategory
    @ObservedObject var absorptionScheme: AbsorptionScheme
    var helpSheet: FoodItemListViewSheets.State
    var foodItemListTitle: String
    var composedFoodItemTitle: String
    @Binding var showingMenu: Bool
    private var draftFoodItem: FoodItemViewModel
    @State private var searchString = ""
    @State private var showCancelButton: Bool = false
    @State private var showFavoritesOnly = false
    @State private var activeSheet: FoodItemListViewSheets.State?
    @State private var showingAlert: Bool = false
    @State private var errorMessage: String = ""
    
    @FetchRequest(
        entity: FoodItem.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \FoodItem.name, ascending: true)
        ]
    ) var foodItems: FetchedResults<FoodItem>
    
    private var filteredFoodItems: [FoodItemViewModel] {
        if searchString == "" {
            return showFavoritesOnly ? foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.favorite && $0.category == self.category } : foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.category == self.category }
        } else {
            return showFavoritesOnly ? foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.favorite && $0.category == self.category && $0.name.lowercased().contains(searchString.lowercased()) } : foodItems.map { FoodItemViewModel(from: $0) } .filter { $0.category == self.category && $0.name.lowercased().contains(searchString.lowercased()) }
        }
    }
    
    var composedFoodItem: ComposedFoodItemViewModel {
        let composedFoodItem = ComposedFoodItemViewModel(name: composedFoodItemTitle)
        for foodItem in foodItems {
            if foodItem.category == self.category.rawValue && foodItem.amount > 0 {
                composedFoodItem.add(foodItem: FoodItemViewModel(from: foodItem))
            }
        }
        return composedFoodItem
    }
    
    init(category: FoodItemCategory, absorptionScheme: AbsorptionScheme, helpSheet: FoodItemListViewSheets.State, foodItemListTitle: String, composedFoodItemTitle: String, showingMenu: Binding<Bool>) {
        self.absorptionScheme = absorptionScheme
        self.category = category
        self.helpSheet = helpSheet
        self.foodItemListTitle = foodItemListTitle
        self.composedFoodItemTitle = composedFoodItemTitle
        self._showingMenu = showingMenu
        self.draftFoodItem = FoodItemViewModel(
            name: "",
            category: category,
            favorite: false,
            caloriesPer100g: 0.0,
            carbsPer100g: 0.0,
            sugarsPer100g: 0.0,
            amount: 0
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack {
                    List {
                        // Search view
                        SearchView(searchString: self.$searchString, showCancelButton: self.$showCancelButton)
                            .padding(.horizontal)
                        Text("Tap to select, long press to edit").font(.caption)
                        ForEach(self.filteredFoodItems) { foodItem in
                            FoodItemView(composedFoodItem: composedFoodItem, foodItem: foodItem, category: self.category)
                                .environment(\.managedObjectContext, self.managedObjectContext)
                        }
                        .onDelete(perform: self.deleteFoodItem)
                    }
                }
                .disabled(self.showingMenu ? true : false)
                .navigationBarTitle(foodItemListTitle)
                .navigationBarItems(
                    leading: HStack {
                        Button(action: {
                            withAnimation {
                                self.showingMenu.toggle()
                            }
                        }) {
                            Image(systemName: self.showingMenu ? "xmark" : "line.horizontal.3")
                            .imageScale(.large)
                        }
                        
                        Button(action: {
                            withAnimation {
                                self.activeSheet = helpSheet
                            }
                        }) {
                            Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .padding()
                        }.disabled(self.showingMenu ? true : false)
                    },
                    trailing: HStack {
                        Button(action: {
                            withAnimation {
                                self.showFavoritesOnly.toggle()
                            }
                        }) {
                            if self.showFavoritesOnly {
                                Image(systemName: "star.fill")
                                .foregroundColor(Color.yellow)
                                .padding()
                            } else {
                                Image(systemName: "star")
                                .foregroundColor(Color.gray)
                                .padding()
                            }
                        }.disabled(self.showingMenu ? true : false)
                        
                        Button(action: {
                            // Add new food item
                            activeSheet = .addFoodItem
                        }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundColor(.green)
                        }.disabled(self.showingMenu ? true : false)
                    }
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .sheet(item: $activeSheet) {
                sheetContent($0)
            }
            .alert(isPresented: self.$showingAlert) {
                Alert(
                    title: Text("Notice"),
                    message: Text(self.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            
            if !self.composedFoodItem.foodItems.isEmpty {
                BottomSheetView(maxHeight: geometry.size.height * 0.95) {
                    bottomSheetContent()
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
    
    private func deleteFoodItem(at offsets: IndexSet) {
        offsets.forEach { index in
            guard let foodItem = self.filteredFoodItems[index].cdFoodItem else {
                errorMessage = NSLocalizedString("Cannot delete food item", comment: "")
                showingAlert = true
                return
            }
            
            // Delete typical amounts first
            let typicalAmountsToBeDeleted = foodItem.typicalAmounts
            if typicalAmountsToBeDeleted != nil {
                for typicalAmountToBeDeleted in typicalAmountsToBeDeleted! {
                    self.managedObjectContext.delete(typicalAmountToBeDeleted as! TypicalAmount)
                }
                foodItem.removeFromTypicalAmounts(typicalAmountsToBeDeleted!)
            }
            
            // Delete food item
            self.managedObjectContext.delete(foodItem)
        }
        
        try? AppDelegate.viewContext.save()
    }
    
    @ViewBuilder
    private func bottomSheetContent() -> some View {
        switch category {
        case .product:
            ComposedFoodItemEvaluationView(absorptionScheme: absorptionScheme, composedFoodItem: composedFoodItem)
        case .ingredient:
            FoodItemComposerView(composedFoodItem: composedFoodItem)
        }
    }
    
    @ViewBuilder
    private func sheetContent(_ state: FoodItemListViewSheets.State) -> some View {
        switch state {
        case .addFoodItem:
            FoodItemEditor(
                navigationBarTitle: NSLocalizedString("New \(category.rawValue)", comment: ""),
                draftFoodItem: draftFoodItem,
                category: category
            ).environment(\.managedObjectContext, managedObjectContext)
        case .productsListHelp:
            HelpView(helpScreen: .productsList)
        case .ingredientsListHelp:
            HelpView(helpScreen: .ingredientsList)
        }
    }
}