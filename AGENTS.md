# AGENTS.md

## Overview
This document outlines the guidelines and best practices for developing AI Agents within the Flutter application designed for desktop platforms (Windows, MacOS, and Linux). It is essential that all agents adhere to these principles to ensure maintainability, clarity, and efficiency in the codebase.

## Development Guidelines

### 1. Code Clarity and Maintainability
- **Clean Code Principles**: All source code must be clear, understandable, and maintainable. Follow the Clean Code principles to enhance readability and reduce complexity.
- **Single Responsibility Principle**: Each file, class, and method/function should have a single responsibility. This minimizes code duplication and logic duplication, promoting high reusability.
- **Limit file/class/function size**: Keep files, classes, and functions short and focused to make code easier to read, test, and maintain. As a soft guideline, prefer files under ~400 lines, classes under ~200 lines, and functions/methods under ~80 lines; when these sizes are exceeded, extract components, helpers, or widgets into smaller, well-named files. Exceptions are allowed with a short justification in the pull request description, and reviewers should flag large units and suggest refactors where appropriate.

### 2. State Management
- **Riverpod**: Utilize Riverpod for state management within the application. Ensure that state management is efficient and follows best practices to maintain application performance.

### 3. Library Usage
- **Stable Libraries**: Use libraries that are stable, trusted, and actively maintained. Avoid using libraries that are deprecated or no longer supported.

### 4. Avoid Deprecated Code
- **No Deprecated Classes/Methods**: Ensure that no deprecated classes, methods, or functions are used in the codebase. Regularly check for updates and replacements for deprecated features.

### 5. Code Analysis
- **Run Flutter Analyze**: Always run `flutter analyze` after completing any task (creating/updating code, fixing bugs, etc.) to ensure there are no compile/build errors. This step is crucial for maintaining code quality.

### 6. Documentation
- **English Documentation**: All documentation must be written in English. It should be clear, professional, and closely aligned with real-world practices. Avoid speculation and ensure accuracy in all descriptions.

### 7. Responsive Design
- **Adaptive UI**: All screens, layouts, and UI components must be designed responsively to accommodate a range of screen sizes and window dimensions on desktop platforms (Windows, MacOS, Linux).
- **Implementation Guidance**: Prefer flexible layouts (e.g., MediaQuery, LayoutBuilder, FractionallySizedBox), adaptive widgets, and well-defined breakpoints to ensure consistent experience across sizes.

## Conclusion
By adhering to these guidelines, we can ensure that our AI Agents are developed in a manner that is efficient, maintainable, and aligned with industry best practices. This will contribute to the overall success and reliability of the application.