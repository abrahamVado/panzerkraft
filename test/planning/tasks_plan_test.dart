import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  //1.- Confirm the tasks document exists where expected.
  test('tasks plan document is present', () {
    final file = File('docs/flutter_demo_tasks/tasks.md');

    //2.- Verify file presence to ensure planning guidance is accessible.
    expect(file.existsSync(), isTrue, reason: 'tasks.md should be created for planning');

    //3.- Ensure the document includes each major planning section heading.
    final content = file.readAsStringSync();
    const expectedSections = [
      '## 1. Authentication Shell',
      '## 2. Dashboard Experience',
      '## 3. Ride Creation Map Flow',
      '## 4. Route Selection Workflow',
      '## 5. Auction Simulation',
      '## 6. Integration & Navigation',
      '## 7. Tooling & Quality Gates',
    ];

    //4.- Assert every section is present to keep the plan comprehensive.
    for (final section in expectedSections) {
      expect(content.contains(section), isTrue, reason: 'Missing section: $section');
    }
  });
}
