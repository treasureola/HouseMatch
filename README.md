# sd-tiks


## January Goals
- Frontend integrates with database
- HostBackend on AWS Server 
- Backend integrates with database
- backend integrates with machine learning
- backed interates with frontend
- Machine learning (Document Journey) 
  - Encode and include details data in the machine lerning model
## February Goals
- Improve machine learning accuracy
## March Goals
- 
## April Goals
-



Frontend - Kweku:

In our project, I was responsible for designing and developing the front end, which plays a crucial role in ensuring the application is user-friendly, supports seamless navigation, and integrates effectively with the backend functionality. My focus was on creating an intuitive and engaging interface to enhance the overall user experience.

Key Features of the Front End:

1. User Account Management:
    * Implemented functionality for user registration and authentication, enabling seamless sign-up and login processes.
2. Interactive Swipe Mechanism:
    * Developed a swipe feature, allowing users to swipe left or right. This interaction helps gather insights into user preferences, which inform predictions and recommendations tailored to individual interests.
3. Personalized Housing/Rental Preferences:
    * Enabled users to set specific housing and rental preferences based on the available options, ensuring that they can easily find properties matching their criteria.


Data Flow - Syl:

Key Features of the Data Flow:
1. Initialization: Set up Firebase tables to store user data and preferences.
2. Class Definition: Create classes to represent database entities, such as users and preferences.
3. API Integration: Connect to the necessary API to retrieve property data.
4. User Addition:
    * Add the new user to the database.
    * Store the user's preferences along with their profile information.


Machine Learning- Treasure:

1. Machine Learning: Implemented a basic recommendation system using a content based model where the list of houses are filtered and recommended to users based on their preferences such as price and square foot and also based on their liked houses
2. MapUI: Implemented Implement a map ui that will be used for the geolocation implementation by Issouf. The user will have the opportunity to  look for housing recommendations within a particular area


Backend - Issouf:
1. User Authentication System:
    * Implemented a secure authentication module to manage user access, including functionalities such as user registration, login, password recovery, and logout.
    * Utilized industry-standard security practices to ensure data protection and session management.
    * Designed scalable middleware to validate user requests
2. Retrieval of Property Listings from API:
    * Established a reliable connection with external APIs 
    * Integrated mechanisms for parsing, validating, and storing the API responses 
    * Implemented error-handling procedures
    * Enabled search or filtering capabilities on the backend
    * Implemented in with prototype sqlitedb
3. Geolocation Integration:
    * Integrated geolocation services to enhance the user experience 
    * Leveraged Google Maps Api tools
    * RapidApi Realtor Search provides location which could take in location and display nearby properties
    * Integration with Treasure’s initial mapUI
  

These developments form the backbone of a scalable , real-time information retrieval, and seamless integration of location-based features. This work has enabled a infrastructure for handling user interactions, property data, and geolocation insights. Testing initially for high concurrency and scalability.
