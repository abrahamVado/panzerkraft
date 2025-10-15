# Taxi Demo Flutter App Task Breakdown

## 1. Authentication Shell
- Define a fake credential list in a secure configuration layer (e.g., local JSON or Dart constant service).
- Build a login screen with email and password fields plus validation states.
- Implement sign-in logic that verifies against the fake credential list and extracts the rider name from the email prefix.
- Persist the signed-in rider in memory for dashboard access.
- Add widget and integration tests for authentication flow success and failure states.

## 2. Dashboard Experience
- Create a dashboard screen showing the authenticated rider's name.
- Surface sections for: bank information, ride history, total rides, total kilometers, evaluation score, current trip (if any), and a call-to-action button to create a taxi ride.
- Mock domain services returning dashboard metrics and live trip data.
- Ensure the dashboard reuses mock data that can be controlled in tests.
- Write widget tests validating data rendering and button availability.

## 3. Ride Creation Map Flow
- When the dashboard call-to-action is pressed, navigate to a dedicated map screen.
- Initialize Google Maps centered on the rider's GPS position with maximum zoom and proper permissions messaging.
- Overlay a floating menu with options "Create a ride for me" and "Create a ride for someone else".
- Persist the selected mode for subsequent forms and testing.

## 4. Route Selection Workflow
- Provide separate form inputs (with autocomplete) to capture start and destination points.
- Render the selected points on Google Maps and fetch available routes via the Directions API.
- Display route options to the rider with metadata (distance, ETA).
- Include a call-to-action button to trigger ride auction creation once both points are set.
- Cover form validation and route display logic with widget tests.

## 5. Auction Simulation
- On auction creation, simulate between five and ten taxi bids with amounts following a normal distribution around a base fare (standard deviation ≈ 10 MXN).
- Render bids in a list that allows single selection and highlight the current choice.
- After a bid selection, generate a random wait time between five and seven minutes and show it as an estimated arrival countdown.
- Once the countdown expires, prompt the rider to either cancel or continue waiting.
- Implement an indefinite incremental stopwatch if the rider keeps waiting, with controls to cancel or start the ride.
- Provide unit tests for bid generation math and widget tests for countdown/stopwatch transitions.

## 6. Integration & Navigation
- Wire authentication, dashboard, map flow, auction, and ride states together using a predictable state-management solution.
- Ensure navigation routes and back-stack behaviors align with user expectations.
- Add integration tests covering the end-to-end flow from login through auction start.

## 7. Tooling & Quality Gates
- Configure CI to run `flutter analyze`, `flutter test`, and any custom linters.
- Document setup steps for Maps API keys, fake credential updates, and data mocks.
- Maintain code size guidelines by splitting widgets/services into files smaller than 700 lines.
