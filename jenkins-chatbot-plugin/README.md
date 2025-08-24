# Student Chatbot Jenkins Plugin

A Jenkins plugin that provides an interactive chatbot interface to help students start numbered Jenkins builds.

## Features

- 🤖 **Interactive Chatbot**: Web-based chat interface for students
- 🔢 **Numbered Build Support**: Automatically detects and manages numbered builds
- 👥 **Student Identification**: Tracks individual student sessions
- 🚀 **Build Management**: Start builds through natural language commands
- 📋 **Build Listing**: Show available builds to students
- ❓ **Help System**: Built-in help and guidance

## Installation

1. Build the plugin:
   ```bash
   mvn clean package
   ```

2. Install the generated `.hpi` file in Jenkins:
   - Go to Jenkins → Manage Jenkins → Manage Plugins
   - Upload `target/student-chatbot.hpi`

## Usage

### For Instructors

1. **Create numbered builds** following the naming convention:
   - `student-build-01`
   - `student-build-02` 
   - `build-1`, `build-2`, etc.

2. **Configure build parameters** (optional):
   - `STUDENT_ID` - automatically populated
   - `BUILD_NUMBER` - automatically populated

### For Students

1. **Access the chatbot** at: `http://your-jenkins/student-chatbot`

2. **Chat commands**:
   - `"help"` - Show available commands
   - `"list"` or `"show builds"` - List available builds
   - `"build 1"` or `"start 1"` - Start build number 1
   - `"run 2"` - Start build number 2

3. **Quick actions**: Use the quick action buttons for common tasks

## Chat Interface

The chatbot provides:
- **Natural language processing** for build commands
- **Real-time messaging** with typing indicators
- **Build status feedback** and error handling
- **Student session tracking** with unique IDs
- **Responsive design** that works on mobile and desktop

## Example Interactions

```
Student: "hi"
Bot: "👋 Hello! I'm here to help you start your Jenkins builds..."

Student: "list"
Bot: "📋 Available Builds:
     Build 1 - student-build-01
     Build 2 - student-build-02
     ..."

Student: "build 1"
Bot: "🚀 Build 1 started! Your build has been queued..."
```

## Development

### Building
```bash
mvn clean compile
mvn test
mvn package
```

### Testing
```bash
mvn hpi:run
```
Then visit: http://localhost:8080/jenkins/student-chatbot

### Project Structure
```
src/main/java/io/jenkins/plugins/chatbot/
├── ChatbotRootAction.java      # Main plugin entry point
├── ChatbotService.java         # Business logic and NLP
├── ChatbotResponse.java        # Response data structure
└── BuildInfo.java             # Build information model

src/main/resources/
└── io/jenkins/plugins/chatbot/ChatbotRootAction/
    └── index.jelly            # Web UI template

src/test/java/
└── io/jenkins/plugins/chatbot/
    └── ChatbotServiceTest.java # Unit tests
```

## Configuration

The plugin automatically discovers builds with these naming patterns:
- `student-build-XX` (where XX is a number)
- `build-X` (where X is a number)

No additional configuration is required.

## Requirements

- Jenkins 2.401.3+
- Java 11+
- Modern web browser with JavaScript enabled

## License

Apache License 2.0
