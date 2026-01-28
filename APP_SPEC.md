# Role
Act as a Senior Flutter Developer specializing in Desktop (Windows & MacOS) applications.

# Project Goal
Create a Flutter Desktop Admin Tool used to send Firebase Push Notifications (FCM) via the HTTP v1 API.

# Key Architectural Constraints
1.  **Platform:** Windows and MacOS.
2.  **No Client SDKs:** Do NOT use `firebase_messaging` or `firebase_core`. This is an admin tool that sends notifications, not a client that receives them.
3.  **State Management:** Use Riverpod (or Provider) for managing application state.
4.  **Local Database:** Use `sqlite` (sqflite_common_ffi) or `isar` to store local data.

# Core Features & Requirements

## 1. Multi-Profile Management (Service Accounts)
The app must support multiple profiles. Each profile corresponds to a specific project context.
* **Input:** Users upload a Firebase Service Account JSON file (via `file_selector`).
* **Storage:** Store the path/content of this JSON file securely locally.
* **Switching:** Users can switch between different Service Accounts. Switching accounts must reset the active Supabase config and History view.

## 2. Supabase Integration (Dynamic Config)
Since each Service Account relates to a backend, the user must manually configure Supabase connection details for the active profile.
* **Settings UI:** Inputs for `Supabase URL` and `Supabase Anon/Service Key`.
* **Functionality:** Use these credentials to fetch a list of `device_tokens` from a remote Supabase table.
* **Security:** Store these keys using `flutter_secure_storage`.

## 3. Notification Sending Logic (The Core)
Use the `googleapis_auth` package to authenticate using the Service Account JSON.
* **API:** Use the Firebase Cloud Messaging (FCM) v1 HTTP API to send messages.
* **Modes:**
    * **Single/Multi Device:** Send to specific tokens fetched from Supabase.
    * **Topic:** Send to a specific topic string (e.g., "news", "updates").
* **Payload UI:** Inputs for Title, Body, Image URL, and Key-Value Data pairs.

## 4. History & Local Persistence
All sent messages must be logged locally.
* **Entity:** `NotificationHistory` (Fields: timestamp, title, body, list of target tokens/topic, status, service_account_id).
* **Relationship:** History is tied to the specific Service Account currently active.

# Suggested Project Structure
* `lib/core`: Utils, Constants, JSON parsers.
* `lib/features/auth`: Handling Service Account files and Google Auth.
* `lib/features/settings`: Supabase Config UI and logic.
* `lib/features/dashboard`:
    * `token_list`: Table view of tokens from Supabase.
    * `composer`: Form to create and send notifications.
    * `history`: List of past logs.

# Deliverable
Provide a step-by-step implementation plan, folder structure, and the essential code snippets for:
1.  The Service Account authentication logic using `googleapis_auth`.
2.  The Local Database schema for storing Profiles and History.
3.  The Repository logic for fetching tokens from a dynamic Supabase client.