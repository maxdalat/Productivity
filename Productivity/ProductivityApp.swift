import SwiftUI
import Starscream

struct ProductivityApp: View {
	struct Block: Identifiable, Codable {
		let id = UUID()
		var name: String
		var progressToday: Int
		var goalToday: Int
		var color: String
		var isCompleted: Bool = false
		var isHidden: Bool = false
	}
	
	@State private var blocks: [Block] = []
	@State private var completedIndices: [Int] = []
	@State private var isPresented = false
	@State private var isDarkMode = false
	@State private var habitName: String = ""
	@State private var habitPerDay: Int = 1
	@State private var habitColor: Color = .red
	@State private var selectedBlockIndex: Int? = nil // For swipe left action
	
		// Color Palette
	let prechosenColors: [Color] = [
		Color(hex: "#405952"),
		Color(hex: "#9C9B7A"),
		Color(hex: "#FFD393"),
		Color(hex: "#FF974F"),
		Color(hex: "#F54F29")
	]
	
		// Timer until midnight
	@State private var hours: Int = 0
	@State private var minutes: Int = 0
	@State private var seconds: Int = 0
	
	let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	
	
	func updateTimerUntilMidnight() {
		let calendar = Calendar.current
		let now = Date()
		let endOfDay = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)
		let components = calendar.dateComponents([.hour, .minute, .second], from: now, to: endOfDay)
		hours = components.hour ?? 0
		minutes = components.minute ?? 0
		seconds = components.second ?? 0
	}
	
	
	func resetDay() {
		print("Resetting day")
		blocks.indices.forEach { index in
			blocks[index].progressToday = 0
			if completedIndices.contains(index) {
				completedIndices.removeAll(where: { $0 == index })
				blocks.append(blocks[index])
			}
		}
		saveData()
	}
	
	func increaseProgress(for blockIndex: Int) {
		if blocks[blockIndex].progressToday < blocks[blockIndex].goalToday {
				// Create a mutable binding to the block at the specified index
			var block = blocks[blockIndex]
			
				// Modify the block
			block.progressToday += 1
			
				// Update the block in the array
			blocks[blockIndex] = block
			
			if block.progressToday == block.goalToday {
				withAnimation {
					block.isCompleted = true
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					withAnimation(.linear(duration: 0.2)) {
						if let completedBlockIndex = blocks.firstIndex(where: { $0.id == block.id }) {
							completedIndices.append(completedBlockIndex)
						}
					}
					DispatchQueue.main.asyncAfter(deadline: .now()) {
						if let completedBlockIndex = blocks.firstIndex(where: { $0.id == block.id }) {
							blocks.remove(at: completedBlockIndex)
							saveData()
						}
					}
				}
			}
		}
		saveData()
	}
	
	func newHabit() {
		let existingHabitIndex = blocks.firstIndex(where: { $0.name == habitName })
		
		if let index = existingHabitIndex {
				// Habit already exists, update its goal
			blocks[index].goalToday = habitPerDay
		} else {
				// Habit doesn't exist, create a new block
			let newBlock = Block(name: habitName, progressToday: 0, goalToday: habitPerDay, color: habitColor.hexString(), isCompleted: false, isHidden: false)
			blocks.append(newBlock)
		}
		
		habitName = ""
		habitPerDay = 1
		habitColor = .red
		saveData()
	}
	
	func deleteBlock(at index: Int) {
		blocks.remove(at: index)
		saveData()
	}
	
	func hideBlock(at index: Int) {
		blocks[index].isHidden.toggle()
		saveData()
	}
	
	func saveData() {
		do {
			let data = try JSONEncoder().encode(blocks)
			UserDefaults.standard.set(data, forKey: "blocks")
		} catch {
			print("Failed to encode data: \(error)")
		}
	}
	
	func loadData() {
		if let data = UserDefaults.standard.data(forKey: "blocks") {
			do {
				blocks = try JSONDecoder().decode([Block].self, from: data)
			} catch {
				print("Failed to decode data: \(error)")
			}
		}
	}
	
	func habits(for block: Block) -> some View {
		ZStack {
			Rectangle()
				.cornerRadius(10)
				.opacity(block.isHidden ? 0 : 0.4) // Hide the block if it's hidden
				.padding(.all, 5)
				.foregroundColor(.gray)
				// .foregroundColor(Color(hex: block.color))
				.shadow(radius: 10)
				.contentShape(Rectangle()) // Add this line to set the content shape to a rectangle
				.onTapGesture {
					increaseProgress(for: blocks.firstIndex(where: { $0.id == block.id })!)
				}
				.contextMenu {
					Button(action: {
						selectedBlockIndex = blocks.firstIndex(where: { $0.id == block.id })
						isPresented.toggle()
							// Implement the edit block functionality
					}) {
						Label("Edit", systemImage: "pencil")
					}
					Button(action: {
						deleteBlock(at: blocks.firstIndex(where: { $0.id == block.id })!)
					}) {
						Label("Delete", systemImage: "trash")
					}
					Button(action: {
						hideBlock(at: blocks.firstIndex(where: { $0.id == block.id })!)
					}) {
						Label(block.isHidden ? "Unhide" : "Hide", systemImage: block.isHidden ? "eye" : "eye.slash")
					}
				}
			
			VStack(alignment: .leading) {
				Text(block.name)
					.font(.title2)
					.fontWeight(.bold)
					.foregroundColor(block.isCompleted ? .secondary : .primary)
					.strikethrough(block.isCompleted, color: .secondary)
					.padding(.bottom, 5)
				
				HStack {
					Text("Progress: \(block.progressToday)/\(block.goalToday)")
					Spacer()
					Button(action: { increaseProgress(for: blocks.firstIndex(where: { $0.id == block.id })!) }) {
						Image(systemName: "plus.circle")
							.foregroundColor(.blue)
					}
				}
				.foregroundColor(block.isCompleted ? .secondary : .primary)
			} // VStack
			.padding(.all)
			
			if block.isCompleted {
				Image(systemName: "checkmark.circle.fill")
					.foregroundColor(.green)
			}
		} // ZStack
	} // ForEach
	
	var body: some View {
		ZStack {
			VStack(alignment: .leading, spacing: 10) {
				Text("Habits")
					.font(.largeTitle)
					.fontWeight(.bold)
					.padding(.top)
					.padding(.horizontal)
					.foregroundColor(isDarkMode ? .white : .black)
				ScrollView {
					VStack {
						ForEach(blocks) { block in
							habits(for: block)
						}
					}
				}
			}
			VStack { // VStack for the "resetDay" and "Add Habit" button
				Spacer() // Add Spacer to push the VStack containing the buttons to the bottom
				
				HStack {
					Button(action: { resetDay() }) {
						Text("Reset Day")
							.font(.title2)
							.fontWeight(.bold)
							.foregroundColor(.white)
							.padding()
							.background(Color.red)
							.cornerRadius(10)
					}
					
					Spacer()
					
					Button(action: { isPresented.toggle() }) {
						Image(systemName: "plus.circle")
							.resizable()
							.frame(width: 30, height: 30)
							.foregroundColor(.blue)
					}
				}
				.padding()
			}
		}
		.navigationBarItems(trailing:
								Button(action: { isDarkMode.toggle() }) {
			Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
				.resizable()
				.frame(width: 30, height: 30)
				.foregroundColor(.blue)
		}
		)
		.navigationBarTitle("", displayMode: .inline)
		.navigationBarHidden(true)
		.sheet(isPresented: $isPresented) {
			VStack {
				Text("New Habit")
					.font(.title)
					.fontWeight(.bold)
					.padding()
				
				VStack(alignment: .leading, spacing: 20) {
					ZStack {
						Rectangle()
							.fill(Color.gray)
							.frame(height: 40)
							.cornerRadius(15)
							.opacity(0.2)
						TextField("Habit Name", text: $habitName)
							.font(.title2)
							.textFieldStyle(DefaultTextFieldStyle())
							.padding(.leading)
					}
					.padding(.leading)
					.padding(.trailing)
					
					Stepper(value: $habitPerDay, in: 1...10) {
						Text("Times per Day: \(habitPerDay)")
							.font(.title2)
							.padding(.leading)
					}
					.padding(.trailing)
					
					HStack {
						ForEach(prechosenColors, id: \.self) { color in
							Button(action: {habitColor = color}) { color
								.cornerRadius(10)
								.frame(height: 30)
								.overlay(
									RoundedRectangle(cornerRadius: 10)
										.stroke(habitColor == color ? Color.blue : Color.clear, lineWidth: 2)
								)
							}
						}
						.padding(.leading)
						ColorPicker("", selection: $habitColor, supportsOpacity: false)
							.font(.title2)
							.padding(.trailing)
					}
					
				}
				
				Spacer()
				
				Button(action: {
					isPresented.toggle()
					newHabit()
				}) {
					Text("Add Habit")
						.font(.title2)
						.fontWeight(.bold)
						.foregroundColor(.white)
						.padding(.all)
						.frame(width: 400.0, height: 75.0)
						.background(Color.blue)
						.cornerRadius(10)
				}
			}
		}
	}
}
struct EditHabitView: View {
	@Binding var block: ContentView.Block
	@Binding var isPresented: Bool
	
		// Add additional properties or bindings as needed for editing
	
	var body: some View {
		VStack {
			Text("Edit Habit")
				.font(.title)
				.fontWeight(.bold)
				.padding()
			
			VStack(alignment: .leading, spacing: 20) {
					// ... (The same content as in AddHabitView)
					// Modify the fields and bindings as needed for editing
			}
			
			Spacer()
			
			Button(action: {
				isPresented.toggle()
					// Handle any additional logic for editing the habit
			}) {
				Text("Save Changes")
					.font(.title2)
					.fontWeight(.bold)
					.foregroundColor(.white)
					.padding(.all)
					.frame(width: 400.0, height: 75.0)
					.background(Color.blue)
					.cornerRadius(10)
			}
		}
	}
}
struct AddHabitView: View {
	@Binding var isPresented: Bool
	var onSave: () -> Void
	
		// Add properties or bindings for creating new habits
	
	var body: some View {
		VStack {
			Text("New Habit")
				.font(.title)
				.fontWeight(.bold)
				.padding()
			
			VStack(alignment: .leading, spacing: 20) {
					// ... (The same content as in your original code for creating new habits)
					// Modify the fields and bindings as needed for creating
			}
			
			Spacer()
			
			Button(action: {
				isPresented.toggle()
				onSave() // Call the onSave closure to save the new habit
			}) {
				Text("Add Habit")
					.font(.title2)
					.fontWeight(.bold)
					.foregroundColor(.white)
					.padding(.all)
					.frame(width: 400.0, height: 75.0)
					.background(Color.blue)
					.cornerRadius(10)
			}
		}
	}
}


extension Color {
	func hexString() -> String {
		guard let components = UIColor(self).cgColor.components else { return "" }
		let red = Float(components[0])
		let green = Float(components[1])
		let blue = Float(components[2])
		return String(format: "#%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
	}
	
	init(hex: String) {
		var formattedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		if formattedHex.count == 6 {
			formattedHex = "FF" + formattedHex
		}
		
		var rgbValue: UInt64 = 0
		Scanner(string: formattedHex).scanHexInt64(&rgbValue)
		
		if let r = Double(exactly: (rgbValue & 0xFF0000) >> 16) {
			let g = Double(exactly: (rgbValue & 0x00FF00) >> 8) ?? 0
			let b = Double(exactly: rgbValue & 0x0000FF) ?? 0
			
			self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
		} else {
			self.init(red: 0, green: 0, blue: 0)
		}
	}
}

struct ProductivityApp_Previews: PreviewProvider {
	static var previews: some View {
		ProductivityApp()
	}
}
