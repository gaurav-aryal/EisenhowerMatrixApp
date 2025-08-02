//
//  ContentView.swift
//  EisenhowerMatrixApp
//
//  Created by user280681 on 8/2/25.
//

import SwiftUI

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var priority: TaskPriority
    var isCompleted: Bool = false
    var dateCreated: Date = Date()
    
    init(title: String, description: String, priority: TaskPriority) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.priority = try container.decode(TaskPriority.self, forKey: .priority)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(priority, forKey: .priority)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(dateCreated, forKey: .dateCreated)
    }
    
    // Custom coding keys to handle UUID
    private enum CodingKeys: String, CodingKey {
        case id, title, description, priority, isCompleted, dateCreated
    }
    
}

enum TaskPriority: String, CaseIterable, Codable {
    case urgentImportant = "Urgent & Important"
    case urgentNotImportant = "Urgent & Not Important"
    case notUrgentImportant = "Not Urgent & Important"
    case notUrgentNotImportant = "Not Urgent & Not Important"
    
    var color: Color {
        switch self {
        case .urgentImportant: return .red
        case .urgentNotImportant: return .orange
        case .notUrgentImportant: return .blue
        case .notUrgentNotImportant: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .urgentImportant:
            return "exclamationmark.triangle.fill"
        case .urgentNotImportant:
            return "⏰"
        case .notUrgentImportant:
            return "star.fill"
        case .notUrgentNotImportant:
            return "🗑️"
        }
    }
}
}

// MARK: - Data Manager
class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    init() {
        loadSampleData()
    }
    
    func addTask(title: String, description: String, priority: TaskPriority) {
        let newTask = TaskItem(
            title: title,
            description: description,
            priority: priority
        )
        tasks.append(newTask)
    }
    
    func loadSampleData() {
        tasks = [
            // Urgent & Important - 7 tasks (will show 5 + "More...")
            TaskItem(title: "Deadline project", description: "Complete urgent project", priority: .urgentImportant),
            TaskItem(title: "Team meeting", description: "Prepare for meeting", priority: .urgentImportant),
            TaskItem(title: "Client presentation", description: "Prepare slides", priority: .urgentImportant),
            TaskItem(title: "Budget review", description: "Review quarterly budget", priority: .urgentImportant),
            TaskItem(title: "Emergency call", description: "Handle urgent client call", priority: .urgentImportant),
            TaskItem(title: "Project deadline", description: "Finalize project deliverables", priority: .urgentImportant),
            TaskItem(title: "Critical bug fix", description: "Fix production bug", priority: .urgentImportant),
            
            // Urgent & Not Important - 3 tasks (will show all 3)
            TaskItem(title: "Email responses", description: "Reply to emails", priority: .urgentNotImportant),
            TaskItem(title: "Phone calls", description: "Return calls", priority: .urgentNotImportant),
            TaskItem(title: "Meeting prep", description: "Prepare for team meeting", priority: .urgentNotImportant),
            
            // Not Urgent & Important - 4 tasks (will show all 4)
            TaskItem(title: "Strategic planning", description: "Plan goals", priority: .notUrgentImportant),
            TaskItem(title: "Skill development", description: "Learn technology", priority: .notUrgentImportant),
            TaskItem(title: "Network building", description: "Connect with colleagues", priority: .notUrgentImportant),
            TaskItem(title: "Process improvement", description: "Optimize workflows", priority: .notUrgentImportant),
            
            // Not Urgent & Not Important - 2 tasks (will show all 2)
            TaskItem(title: "Social media", description: "Check updates", priority: .notUrgentNotImportant),
            TaskItem(title: "Some interruptions", description: "Handle distractions", priority: .notUrgentNotImportant)
        ]
    }
    
    func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func tasksForPriority(_ priority: TaskPriority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority }
    }
    
    func moveTask(_ task: TaskItem, to newPriority: TaskPriority) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].priority = newPriority
        }
    }
    
    func reorderTasks(from sourceIndex: Int, to destinationIndex: Int, in priority: TaskPriority) {
        let priorityTasks = tasksForPriority(priority)
        guard sourceIndex < priorityTasks.count && destinationIndex < priorityTasks.count else { return }
        
        let sourceTask = priorityTasks[sourceIndex]
        let destinationTask = priorityTasks[destinationIndex]
        
        // Find the actual indices in the main tasks array
        if let sourceIndexInMain = tasks.firstIndex(where: { $0.id == sourceTask.id }),
           let destIndexInMain = tasks.firstIndex(where: { $0.id == destinationTask.id }) {
            let task = tasks.remove(at: sourceIndexInMain)
            tasks.insert(task, at: destIndexInMain)
        }
    }
    
    func updateTask(_ task: TaskItem, title: String, description: String, priority: TaskPriority) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = title
            tasks[index].description = description
            tasks[index].priority = priority
        }
    }
}

// MARK: - Drop View Delegate
struct DropViewDelegate: DropDelegate {
    let taskManager: TaskManager
    let targetPriority: TaskPriority
    
    func performDrop(info: DropInfo) -> Bool {
        print("Drop attempted for \(targetPriority.rawValue)")
        
        guard let itemProvider = info.itemProviders(for: [.text]).first else { 
            print("No item provider found")
            return false 
        }
        
        itemProvider.loadObject(ofClass: NSString.self) { string, error in
            if let error = error {
                print("Error loading object: \(error)")
                return
            }
            
            if let taskIdString = string as? String,
               let taskId = UUID(uuidString: taskIdString) {
                print("Task ID decoded: \(taskId)")
                
                DispatchQueue.main.async {
                    if let task = self.taskManager.tasks.first(where: { $0.id == taskId }) {
                        print("Found task: \(task.title), current priority: \(task.priority.rawValue)")
                        
                        // Only move if the priority is different
                        if task.priority != self.targetPriority {
                            print("Moving task from \(task.priority.rawValue) to \(self.targetPriority.rawValue)")
                            self.taskManager.moveTask(task, to: self.targetPriority)
                        } else {
                            print("Task already in target priority")
                        }
                    } else {
                        print("Task not found")
                    }
                }
            } else {
                print("Failed to decode task ID from: \(string ?? "nil")")
            }
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        print("Drop entered for \(targetPriority.rawValue)")
    }
    
    func dropExited(info: DropInfo) {
        print("Drop exited for \(targetPriority.rawValue)")
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedPriority: TaskPriority?
    @State private var selectedPriorityForAdd: TaskPriority?
    @State private var showingDetail = false
    @State private var showingAddTask = false
    @State private var isDragging = false
    @State private var draggedTaskId: UUID?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Eisenhower Matrix")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "hand.draw")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Drag tasks between quadrants to change priority")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                
                // Matrix Grid
                VStack(spacing: 0) {
                    // Top section: Urgent quadrants
                    HStack(spacing: 12) {
                        matrixQuadrant(priority: .urgentImportant, color: .red)
                        matrixQuadrant(priority: .urgentNotImportant, color: .orange)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Center section with proper spacing
                    Spacer()
                        .frame(height: 120)
                    
                    // Bottom section: Not Urgent quadrants (truly centered)
                    HStack {
                        Spacer()
                        HStack(spacing: 12) {
                            matrixQuadrant(priority: .notUrgentImportant, color: .blue)
                            matrixQuadrant(priority: .notUrgentNotImportant, color: .gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 120)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager, priority: selectedPriorityForAdd ?? .urgentImportant)
        }
        .sheet(isPresented: $showingDetail) {
            if let priority = selectedPriority {
                PriorityDetailView(taskManager: taskManager, priority: priority)
            }
        }
    }
    
    private func matrixQuadrant(priority: TaskPriority, color: Color) -> some View {
        let tasks = taskManager.tasksForPriority(priority)
        
        return VStack(spacing: 6) {
            // Header with title - fixed layout
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: priority.icon)
                        .foregroundColor(color)
                        .font(.title3)
                    
                    Spacer()
                }
                
                Text(priority.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.8)
            }
            
            // Task list
            VStack(alignment: .leading, spacing: 3) {
                ForEach(tasks.prefix(5)) { task in
                    HStack(spacing: 6) {
                        Button(action: {
                            taskManager.toggleTask(task)
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : color)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(task.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .strikethrough(task.isCompleted)
                                .lineLimit(1)
                            
                            Text(task.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Drag handle indicator
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(color.opacity(0.6))
                            .font(.caption2)
                        
                        Button(action: {
                            taskManager.deleteTask(task)
                        }) {
                            Text("🗑️")
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                    .onDrag {
                        print("Starting drag for task: \(task.title)")
                        return NSItemProvider(object: task.id.uuidString as NSString)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.2), value: true)
                }
                
                if tasks.count > 5 {
                    Text("More...")
                        .font(.caption)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Add button
            Button(action: {
                selectedPriorityForAdd = priority
                showingAddTask = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                        .font(.caption)
                    Text("Add Task")
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(8)
        .frame(width: 180, height: 220)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 1)
        )
        .onTapGesture {
            selectedPriority = priority
            showingDetail = true
        }
        .onDrop(of: [.text], delegate: DropViewDelegate(taskManager: taskManager, targetPriority: priority))
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskPriority
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    HStack {
                        Image(systemName: priority.icon)
                            .foregroundColor(priority.color)
                        Text(priority.rawValue)
                            .foregroundColor(priority.color)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        taskManager.addTask(title: title, description: description, priority: priority)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Priority Detail View
struct PriorityDetailView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskPriority
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTask = false
    
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
                        Text("\(taskManager.tasksForPriority(priority).count) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(taskManager.tasksForPriority(priority).filter { $0.isCompleted }.count) completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(priority.color.opacity(0.1))
                
                // Task List
                List {
                    ForEach(taskManager.tasksForPriority(priority)) { task in
                        TaskRowView(task: task, taskManager: taskManager)
                    }
                    .onDelete(perform: deleteTasks)
                    .onMove(perform: moveTasks)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(priority.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Task") {
                        showingAddTask = true
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        // Edit functionality
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager, priority: priority)
        }
    }
    
    private func getSubtitle(for priority: TaskPriority) -> String {
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
        let tasksToDelete = taskManager.tasksForPriority(priority)
        for index in offsets {
            taskManager.deleteTask(tasksToDelete[index])
        }
    }
    
    private func moveTasks(from source: IndexSet, to destination: Int) {
        let priorityTasks = taskManager.tasksForPriority(priority)
        guard let sourceIndex = source.first, sourceIndex < priorityTasks.count else { return }
        
        let sourceTask = priorityTasks[sourceIndex]
        
        // Find the actual index in the main tasks array
        if let sourceIndexInMain = taskManager.tasks.firstIndex(where: { $0.id == sourceTask.id }) {
            // Calculate the destination index in the main array
            let priorityTaskIndices = taskManager.tasks.enumerated().compactMap { index, task in
                task.priority == priority ? index : nil
            }
            
            if destination < priorityTaskIndices.count {
                let destIndexInMain = priorityTaskIndices[destination]
                taskManager.tasks.move(fromOffsets: IndexSet(integer: sourceIndexInMain), toOffset: destIndexInMain)
            }
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var taskManager: TaskManager
    @State private var showingEditTask = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { taskManager.toggleTask(task) }) {
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
            
            Button(action: {
                showingEditTask = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(task.dateCreated, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(taskManager: taskManager, task: task)
        }
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let task: TaskItem
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    
    init(taskManager: TaskManager, task: TaskItem) {
        self.taskManager = taskManager
        self.task = task
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._priority = State(initialValue: task.priority)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                    .foregroundColor(priority.color)
                                Text(priority.rawValue)
                                    .foregroundColor(priority.color)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        taskManager.updateTask(task, title: title, description: description, priority: priority)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

extension TaskPriority: Identifiable {
    var id: String { rawValue }
}

#Preview {
    ContentView()
}
