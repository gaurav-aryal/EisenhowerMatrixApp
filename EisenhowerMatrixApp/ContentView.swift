//
//  ContentView.swift
//  EisenhowerMatrixApp
//
//  Created by user280681 on 8/2/25.
//

import SwiftUI
import CoreData

// MARK: - Core Data Manager
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "EisenhowerMatrixApp")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Task Model
struct TaskItem: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var priority: Priority
    var isCompleted: Bool
    var dateCreated: Date
    var personId: UUID
    
    enum Priority: String, CaseIterable, Codable {
        case urgentImportant = "Urgent & Important"
        case urgentNotImportant = "Urgent & Not Important"
        case notUrgentImportant = "Not Urgent & Important"
        case notUrgentNotImportant = "Not Urgent & Not Important"
        
        var color: Color {
            switch self {
            case .urgentImportant:
                return .red
            case .urgentNotImportant:
                return .orange
            case .notUrgentImportant:
                return .blue
            case .notUrgentNotImportant:
                return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .urgentImportant:
                return "exclamationmark.triangle.fill"
            case .urgentNotImportant:
                return "clock.fill"
            case .notUrgentImportant:
                return "star.fill"
            case .notUrgentNotImportant:
                return "minus.circle.fill"
            }
        }
    }
}

// MARK: - Person Model
struct PersonItem: Identifiable {
    let id: UUID
    var name: String
    var email: String
    var dateCreated: Date
}

// MARK: - Data Manager
class DataManager: ObservableObject {
    @Published var currentPerson: PersonItem?
    @Published var tasks: [TaskItem] = []
    @Published var persons: [PersonItem] = []
    
    private let context: NSManagedObjectContext
    
    init() {
        self.context = CoreDataManager.shared.container.viewContext
        loadPersons()
        if let firstPerson = persons.first {
            currentPerson = firstPerson
            loadTasksForPerson(firstPerson.id)
        }
    }
    
    // MARK: - Person Management
    func addPerson(name: String, email: String) {
        let person = Person(context: context)
        person.id = UUID()
        person.name = name
        person.email = email
        person.dateCreated = Date()
        
        saveContext()
        loadPersons()
    }
    
    func loadPersons() {
        let request: NSFetchRequest<Person> = Person.fetchRequest()
        
        do {
            let personEntities = try context.fetch(request)
            persons = personEntities.map { person in
                PersonItem(
                    id: person.id ?? UUID(),
                    name: person.name ?? "",
                    email: person.email ?? "",
                    dateCreated: person.dateCreated ?? Date()
                )
            }
        } catch {
            print("Error loading persons: \(error)")
        }
    }
    
    func selectPerson(_ person: PersonItem) {
        currentPerson = person
        loadTasksForPerson(person.id)
    }
    
    // MARK: - Task Management
    func addTask(title: String, description: String, priority: TaskItem.Priority) {
        guard let currentPerson = currentPerson else { return }
        
        let task = Task(context: context)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.priority = priority.rawValue
        task.isCompleted = false
        task.dateCreated = Date()
        task.personId = currentPerson.id
        
        saveContext()
        loadTasksForPerson(currentPerson.id)
    }
    
    func loadTasksForPerson(_ personId: UUID) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "personId == %@", personId as CVarArg)
        
        do {
            let taskEntities = try context.fetch(request)
            tasks = taskEntities.map { task in
                TaskItem(
                    id: task.id ?? UUID(),
                    title: task.title ?? "",
                    description: task.taskDescription ?? "",
                    priority: TaskItem.Priority(rawValue: task.priority ?? "") ?? .urgentImportant,
                    isCompleted: task.isCompleted,
                    dateCreated: task.dateCreated ?? Date(),
                    personId: task.personId ?? UUID()
                )
            }
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            let tasks = try context.fetch(request)
            if let taskToUpdate = tasks.first {
                taskToUpdate.isCompleted.toggle()
                saveContext()
                loadTasksForPerson(task.personId)
            }
        } catch {
            print("Error updating task: \(error)")
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            let tasks = try context.fetch(request)
            if let taskToDelete = tasks.first {
                context.delete(taskToDelete)
                saveContext()
                loadTasksForPerson(task.personId)
            }
        } catch {
            print("Error deleting task: \(error)")
        }
    }
    
    func tasksForPriority(_ priority: TaskItem.Priority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority }
    }
    
    func clearAllTasksForCurrentPerson() {
        guard let currentPerson = currentPerson else { return }
        
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "personId == %@", currentPerson.id as CVarArg)
        
        do {
            let tasksToDelete = try context.fetch(request)
            for task in tasksToDelete {
                context.delete(task)
            }
            saveContext()
            loadTasksForPerson(currentPerson.id)
        } catch {
            print("Error clearing tasks: \(error)")
        }
    }
    
    func loadSampleDataForCurrentPerson() {
        guard let currentPerson = currentPerson else { return }
        
        // Clear existing tasks first
        clearAllTasksForCurrentPerson()
        
        // Add exactly 2 tasks for each priority
        let sampleTasks = [
            ("Deadline project", "Complete the urgent project by end of week", TaskItem.Priority.urgentImportant),
            ("Team meeting", "Prepare for tomorrow's critical meeting", TaskItem.Priority.urgentImportant),
            ("Email responses", "Reply to urgent emails from clients", TaskItem.Priority.urgentNotImportant),
            ("Phone calls", "Return urgent calls from suppliers", TaskItem.Priority.urgentNotImportant),
            ("Strategic planning", "Plan next quarter goals and objectives", TaskItem.Priority.notUrgentImportant),
            ("Skill development", "Learn new technology for future projects", TaskItem.Priority.notUrgentImportant),
            ("Social media", "Check social media updates", TaskItem.Priority.notUrgentNotImportant),
            ("Some interruptions", "Handle minor interruptions and distractions", TaskItem.Priority.notUrgentNotImportant)
        ]
        
        for (title, description, priority) in sampleTasks {
            addTask(title: title, description: description, priority: priority)
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var showingAddTask = false
    @State private var showingPersonSelector = false
    @State private var selectedPriority: TaskItem.Priority?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Matrix Grid
                matrixGridView
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(dataManager: dataManager)
        }
        .sheet(item: $selectedPriority) { priority in
            PriorityDetailView(dataManager: dataManager, priority: priority)
        }
        .sheet(isPresented: $showingPersonSelector) {
            PersonSelectorView(dataManager: dataManager)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Eisenhower Matrix")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingPersonSelector = true }) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                Button(action: { dataManager.loadSampleDataForCurrentPerson() }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            if let currentPerson = dataManager.currentPerson {
                Text("Tasks for: \(currentPerson.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Select a person to view tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }
    
    private var matrixGridView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Quadrant 1: Urgent & Important
                matrixQuadrant(
                    title: "Urgent & Important",
                    subtitle: "Do First",
                    priority: .urgentImportant,
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                // Quadrant 2: Urgent & Not Important
                matrixQuadrant(
                    title: "Urgent & Not Important",
                    subtitle: "Delegate",
                    priority: .urgentNotImportant,
                    color: .orange,
                    icon: "clock.fill"
                )
            }
            
            HStack(spacing: 12) {
                // Quadrant 3: Not Urgent & Important
                matrixQuadrant(
                    title: "Not Urgent & Important",
                    subtitle: "Schedule",
                    priority: .notUrgentImportant,
                    color: .blue,
                    icon: "star.fill"
                )
                
                // Quadrant 4: Not Urgent & Not Important
                matrixQuadrant(
                    title: "Not Urgent & Not Important",
                    subtitle: "Eliminate",
                    priority: .notUrgentNotImportant,
                    color: .gray,
                    icon: "minus.circle.fill"
                )
            }
        }
        .padding()
    }
    
    private func matrixQuadrant(
        title: String,
        subtitle: String,
        priority: TaskItem.Priority,
        color: Color,
        icon: String
    ) -> some View {
        Button(action: { selectedPriority = priority }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    Text("\(dataManager.tasksForPriority(priority).count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(color)
                        .clipShape(Circle())
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            .padding(12)
            .frame(height: 120)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Priority Detail View
struct PriorityDetailView: View {
    @ObservedObject var dataManager: DataManager
    let priority: TaskItem.Priority
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: priority.icon)
                            .font(.title)
                            .foregroundColor(priority.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(priority.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(getSubtitle(for: priority))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(dataManager.tasksForPriority(priority).count) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(dataManager.tasksForPriority(priority).filter { $0.isCompleted }.count) completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(priority.color.opacity(0.1))
                
                // Task List
                List {
                    ForEach(dataManager.tasksForPriority(priority)) { task in
                        TaskRowView(task: task, dataManager: dataManager)
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(priority.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task") {
                        // Add task functionality
                    }
                }
            }
        }
    }
    
    private func getSubtitle(for priority: TaskItem.Priority) -> String {
        switch priority {
        case .urgentImportant:
            return "Do First - These require immediate attention"
        case .urgentNotImportant:
            return "Delegate - These can be delegated to others"
        case .notUrgentImportant:
            return "Schedule - Plan these for later"
        case .notUrgentNotImportant:
            return "Eliminate - Consider removing these tasks"
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        let tasksToDelete = dataManager.tasksForPriority(priority)
        for index in offsets {
            dataManager.deleteTask(tasksToDelete[index])
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { dataManager.toggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .strikethrough(task.isCompleted)
            }
            
            Spacer()
            
            Text(task.dateCreated, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority: TaskItem.Priority = .urgentImportant
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                    .foregroundColor(priority.color)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dataManager.addTask(title: title, description: description, priority: selectedPriority)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Person Selector View
struct PersonSelectorView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddPerson = false
    @State private var newPersonName = ""
    @State private var newPersonEmail = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.persons) { person in
                    Button(action: {
                        dataManager.selectPerson(person)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(person.name)
                                    .font(.headline)
                                Text(person.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if dataManager.currentPerson?.id == person.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Person")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Person") { showingAddPerson = true }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonView(dataManager: dataManager)
            }
        }
    }
}

// MARK: - Add Person View
struct AddPersonView: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Person Details")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                }
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dataManager.addPerson(name: name, email: email)
                        dismiss()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
}

// MARK: - Extensions
extension TaskItem.Priority: Identifiable {
    var id: String { rawValue }
}

#Preview {
    ContentView()
}
