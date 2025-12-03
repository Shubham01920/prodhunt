Project Overview & ArchitectureHigh-Level ArchitectureTech StackFolder StructureConfiguration & Entry PointMain Entry (main.dart)Firebase ConfigurationData Layer (Models)User ModelProduct ModelInteraction Models (Comments, Upvotes)Aggregation Models (Trending)Service Layer (Business Logic)User & Social Graph ServicesProduct & Content ServicesInteraction Services (Voting, Comments)Analytics & Admin ServicesUI Layer (Presentation)Page Navigation StructureScreen Details (Home, Profile, Details)Reusable WidgetsUtility & Helper LayerTheming & Design SystemConstants & ExceptionsSystem Flowcharts & DiagramsAuthentication FlowData Aggregation FlowSocial Graph Flow1. Project Overview & Architecture1.1 High-Level ArchitectureThis project follows a Layered Architecture combined with a Feature-First organization. It strictly separates the Presentation Layer (UI) from the Business Logic Layer (Services) and the Data Layer (Models).Architectural Diagram:Plaintext      [ User Interaction ]
              |
              v
    [ Presentation Layer ]  (lib/pages & lib/widgets)
              |
              v
        [ State Layer ]     (Provider / StreamBuilders)
              |
              v
       [ Service Layer ]    (lib/services)
              |
              v
        [ Data Layer ]      (lib/model)
              |
              v
   [ External Data Source ] (Firebase / AdMob)
1.2 Tech StackComponentTechnologyDescriptionFrontendFlutter (Dart)Cross-platform mobile application framework.AuthFirebase AuthManages Email, Google, and Apple Sign-In.DatabaseCloud FirestoreNoSQL database for real-time data sync.StorageFirebase StorageHosting for User Avatars and Product Images.Backend LogicCloud FunctionsServer-side logic for Trending algorithms (TypeScript).MonetizationGoogle AdMobBanner ads integration.Chartsfl_chartData visualization for the Admin Dashboard.1.3 Directory Structure Referencelib/ads: Monetization logic.lib/Auth: Authentication screens and logic.lib/model: Pure data classes (POJOs).lib/pages: Full-screen views (Scaffolds).lib/services: Business logic and API calls.lib/ui/helper: View Models and Mappers.lib/utils: Constants, Themes, and Exception handling.lib/widgets: Reusable UI components.2. Configuration & Entry Point2.1 Main Entry (lib/main.dart)The bootstrap file responsible for initializing the app environment.Responsibilities:Initializes Flutter Bindings.Initializes Firebase with platform-specific options.Initializes Mobile Ads (Mobile only).Sets up Dependency Injection via MultiProvider.Routing: Defines the global named routes map (/auth, /home, /profile, etc.).Auth Gate: Implements a StreamBuilder listening to FirebaseAuth. It acts as a traffic cop, directing users to the Login Screen or Home Page based on their session state.2.2 Firebase Options (lib/firebase_options.dart)Auto-generated configuration file.Critical: Contains API Keys and App IDs for Android, iOS, and Web.Usage: Passed to Firebase.initializeApp() in main.dart. Never modify this manually; use flutterfire configure.3. Data Layer (Models)The application uses strict Dart classes to define the schema of the NoSQL database.3.1 User Model (user_model.dart)Represents the users collection.Key Fields: userId, username, email, role ('user'/'admin'), followers (List<String>), reputation (int).Logic: Includes helper methods to safely parse nullable fields and convert Firestore Timestamp to Dart DateTime.3.2 Product Model (product_model.dart)Represents the products collection.Key Fields:status: State machine ('draft', 'pending', 'published', 'rejected').upvoteCount: Cached counter for sorting.coverUrl / logoUrl: Visual assets.Immutability: Uses final fields and a copyWith() method for state updates.3.3 Interaction ModelsCommentModel: Supports threaded conversations via parentCommentId. Caches the commenter's userInfo (name/photo) to reduce database reads.UpvoteModel: Represents a many-to-many relationship between Users and Products. Acts as a unique constraint to prevent double-voting.3.4 Aggregation ModelsTrendingModel: Represents a daily snapshot of top products. Used to render the "Trending" tab efficiently by reading 1 document instead of querying thousands.4. Service Layer (Business Logic)This layer handles all communication with Firebase.4.1 Social Interactions (user_service.dart)Handles the Social Graph and User Identity.Follow System: Uses Transactions to ensure that when User A follows User B, both the following array (on A) and followers array (on B) are updated atomically.Profile Management: Handles creating profiles on signup and validating username uniqueness.4.2 Content Creation (product_submit_service.dart)Handles the complex flow of uploading a product.Process:Creates a draft document in Firestore.Compresses images (Logo/Cover).Uploads images to Firebase Storage.Updates the Firestore document with the image URLs.Sets status to pending for admin review.4.3 Engagement ServicesUpvoteService: Manages the toggle logic for upvotes using transactions to ensure the upvoteCount counter is accurate even under high load.CommentService: Manages adding comments and incrementing the commentCount on the parent product.ShareService: Uses share_plus to invoke native sharing and increments a "Virality" counter in Firestore.4.4 Analytics & NotificationsViewService: Implements view counting with deduplication logic (checks if products/{id}/views/{uid} exists before incrementing).NotificationService: Creates documents in the notifications collection when a user receives a comment or upvote.5. UI Layer (Presentation)5.1 Screens (lib/pages/)HomePage: The main hub. Uses TabBarView with AutomaticKeepAlive to maintain the scroll state of the "Trending", "Recommendations", and "All Products" tabs.ProfilePage: Displays user stats (Followers/Following). Uses a real-time stream to update the UI instantly when a user edits their bio.AdminDashboardPage: A specialized view for Admins. Uses fl_chart to visualize upload trends and allows moderation of 'pending' products.ProductDetailedPage: The landing page for a specific product. Shows the full description, gallery, and community discussions.5.2 Widgets (lib/widgets/)ProductCard: The most complex widget. It is "smart"—it listens to its own data streams for Upvotes and Views, allowing it to update numbers in real-time without refreshing the whole list.AnimatedSideDrawer: A custom navigation drawer with slide-and-fade animations and a dynamic header that adapts to the current user's theme.CommentWidget: A recursive widget that renders a comment and its nested replies.5.3 UI Mappers (lib/ui/helper/)ProductUIMapper: Implements the Adapter pattern. It converts different backend models (Raw ProductModel vs. Aggregated TrendingProduct) into a single ProductUI object that the ProductCard can consume.6. Utility Layerconstant.dart: Centralized configuration for Collection Names, Upload Limits, and Regex Patterns.app_theme.dart: Defines the Light and Dark mode ThemeData, ensuring consistent colors and shapes across the app.exception.dart: A custom error handling system that parses raw Firebase errors (e.g., auth/user-not-found) into user-friendly messages.7. System Flowcharts7.1 Authentication & Onboarding FlowThis flowchart describes how a user is authenticated and how their profile is created in the database.PlaintextUser             AuthScreen          UserService       FirebaseAuth      Firestore
 |                   |                    |                 |                |
 |--- Clicks SignUp->|                    |                 |                |
 |                   |--- checkUsername ->|                 |                |
 |                   |                    |                 |                |
 |                   |<-- Returns Bool ---|                 |                |
 |                   |                    |                 |                |
 | [If Taken]        |                    |                 |                |
 |<-- Show Error ----|                    |                 |                |
 |                   |                    |                 |                |
 | [If Available]    |                    |                 |                |
 |                   |--------------------|-- Create User ->|                |
 |                   |                    |                 |                |
 |                   |<-- Returns UID ----|-----------------|                |
 |                   |                    |                 |                |
 |                   |--- createUserProf->|                 |                |
 |                   |                    |--- Writes Doc ->|--------------->|
 |                   |                    |                 |                |
 |<-- Redirect Home -|                    |                 |                |
7.2 Data Aggregation (Trending) FlowThis diagram explains how the "Trending" tab stays fast by avoiding heavy calculations on the phone.Plaintext[ User Upvotes Product ]
        |
        v
[ Update Product Doc in Firestore ]
        |
        v
+--------------------------------------------------+
| CLOUD BACKEND (Serverless Function)              |
|                                                  |
| [ Cloud Function Trigger ]                       |
|           |                                      |
|           v                                      |
| [ Calculate Score & Sort Top 20 ]                |
|           |                                      |
|           v                                      |
| [ Write to 'dailyRankings/{Date}' ]              |
+--------------------------------------------------+
        |
        v
[ Trending Tab (StreamBuilder) ]
        |
        v
[ User Sees Updated Ranking ]
7.3 Social Graph (Follow) TransactionThis explains how UserService keeps follower counts accurate using database transactions.PlaintextAlice                Service              Firestore              Bob
  |                     |                     |                   |
  |--- Follow(Bob) ---->|                     |                   |
  |                     |                     |                   |
  |                     |=== TRANSACTION ===  |                   |
  |                     |-- Read Alice Doc -->|                   |
  |                     |-- Read Bob Doc ---->|                   |
  |                     |                     |                   |
  |                     |-- Update Alice ---->| (Add to following)|
  |                     |-- Update Bob ------>| (Add to followers)|
  |                     |===================  |                   |
  |                     |                     |                   |
  |<-- Success ---------|                     |                   |
8. Implementation Guides8.1 How to Add a New FeatureModel: Create a new file in lib/model/ (e.g., chat_model.dart). Define the fields and fromFirestore factory.Service: Create lib/services/chat_service.dart. Add methods for sendMessage and getMessagesStream.UI: Create lib/pages/chat_page.dart. Use StreamBuilder to listen to the service.Route: Register the new page in the routes map in lib/main.dart.8.2 How to DeployAndroid:Update android/app/build.gradle with your unique Application ID.Run flutter build appbundle.iOS:Open ios/Runner.xcworkspace.Configure Signing & Capabilities.Run flutter build ios.Backend:Deploy Firestore Security Rules via Firebase Console.Deploy Cloud Functions using firebase deploy --only functions.8.3 Common PitfallsState Management: Do not remove MultiProvider from main.dart. It acts as the global dependency injector.Streams: Always handle ConnectionState.waiting in your StreamBuilder to prevent "Red Screen of Death" on null data.Image Caching: When updating profile pictures, the URL usually stays the same. Use the cache-busting technique implemented in edit_profile.dart (appending ?t=timestamp) to force the UI to refresh the image.