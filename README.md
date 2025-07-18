# GrovoApps 🌱

A comprehensive mobile application built with Flutter and Firebase that revolutionizes agricultural operations by connecting farmers, vendors, landlords, and workers in a unified digital ecosystem.

## 🚀 Project Overview

**Grovo** is a mobile application tailored for the agriculture domain that addresses critical communication gaps by providing a centralized platform for agricultural commerce and workforce management.

The project was developed in **two phases**:
- **Phase 1**: Farmer–Vendor commerce system ✅
- **Phase 2**: Landlord–Worker job/task hiring system ✅

### 🎯 Key Features

- **Multi-User Platform**: Supports Farmers, Vendors, Landlords, and Workers
- **Real-time Communication**: Live messaging and notifications
- **Secure Payment System**: Razorpay integration with escrow functionality
- **Aadhar Verification**: OTP-based verification for workers
- **Location-based Services**: GPS tracking and location-based task matching
- **Product Management**: Comprehensive catalog with search and filtering
- **Workforce Management**: Automated labor hiring and task assignment
- **Rating & Review System**: Trust-building through user feedback
- **Weather Integration**: OpenWeather API for farming insights

## 🛠️ Technology Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language

### Backend & Database
- **Firebase** - Backend as a Service
  - Authentication (Email/Password)
  - Firestore Database
  - Cloud Storage
  - Cloud Messaging

### APIs & Services
- **Razorpay API** - Payment processing with escrow
- **OpenWeather API** - Weather data for farmers
- **Google Maps API** - Location services and tracking
- **Lottie Flutter** - Smooth animations

## 🔄 App Workflow

### **1. App Launch & Role Selection**
```
splash_screen → selection_page.dart
```
User selects their role:
- 👨‍🌾 **Farmer**
- 🧑‍💼 **Vendor**
- 🏠 **Landlord** (Phase 2)
- 👷 **Worker** (Phase 2)

### **2. Firebase Authentication**
- Email & password authentication
- Separate auth flows:
  - **Farmer**: `farmer_auth_screen.dart`
  - **Vendor**: `vendor_auth_screen.dart`

## ✅ Phase 1: Farmer-Vendor Commerce System

### 👨‍🌾 **Farmer Dashboard** (`farmer_dashboard_screen.dart`)

#### **Shopping Section**
- 🛍 **Browse Products**
  - Categories: Fertilizers, Seeds, Herbicides, Insecticides, Machinery
  - Product cards with image, price, brand, discount, availability
- 🔍 **Search Functionality**
  - Search products by name across all categories
- ❤️ **Wishlist Management**
  - Stored in Firestore: `/farmers/{uid}/wishlist`
- 🛒 **Shopping Cart**
  - Items stored in `/farmers/{uid}/cart`
  - Product + quantity + price tracking
- 💳 **Order & Payment**
  - Razorpay integration (test UPI: success@razorpay)
  - Orders saved in `orders` collection
- 🔔 **Notifications**
  - Real-time updates via Firestore
  - Stored in `notifications` collection
- 🌦 **Weather Integration**
  - OpenWeather API for live weather information

#### **Work Section** (Phase 2)
- 🏠 **"Hire Workers"** - Landlord functionality
- 👷 **"Find Work"** - Worker functionality

#### **Account Section**
- Profile management
- Order history
- Settings

#### **Tools Section**
- Weather dashboard
- Agricultural tools and resources

### 🧑‍💼 **Vendor Dashboard** (`vendor_dashboard_screen.dart`)

- ➕ **Add Product**
  - Upload image, name, category, brand, price, discount
  - Saved in `products` collection with `vendorId`
- 🗂 **Manage Products**
  - View, Edit, Delete products
  - Stock availability control
- 📦 **View Orders**
  - Orders filtered by `vendorId`
  - Status updates: pending → shipped → delivered
- 🔔 **Notification System**
  - Auto-notify farmers on order status changes

## 🚧 Phase 2: Landlord-Worker Hiring System

### 🏠 **Landlord Flow**

#### **Work Dashboard** (`farmer_work_dashboard.dart`)
- "Request a Worker" button
- "My Requests" management

#### **Request Worker** (`request_worker_screen.dart`)
**Form Fields:**
- Work Type (dropdown)
- Crop Type (dropdown/text)
- Location (with optional map integration)
- Budget (₹) (number input)
- Start/End Date (date pickers)
- Notes/Description (text area)

**Aadhar Verification:**
- Aadhar number input
- OTP verification system
- Verification status stored in user profile

**Payment Escrow System:**
- Razorpay integration for upfront payment
- Payment held in escrow until task completion
- Payment receipt and confirmation

#### **My Requests** (`my_requests_screen.dart`)
- List all requests with color-coded status indicators
- Worker information (once accepted)
- Action buttons based on current status
- Individual request details view
- "Mark Complete" button
- Rating system after completion

### 👷 **Worker Flow**

#### **Available Tasks** (`available_tasks_screen.dart`)
- List available tasks sorted by location
- Job type, payment, duration, status display
- Filtering options (work type, payment range, dates)
- **Aadhar Verification Requirement:**
  - Verification prompt if not completed
  - Only verified workers can accept tasks

#### **Task Details** (`task_detail_screen.dart`)
- Complete job information
- "Accept Task" button
- Landlord contact information
- Post-completion features:
  - "Request Verification" button
  - Rating system for landlord

## 🔐 Security & Payment System

### **Payment Flow**
1. **Escrow Creation**: Landlord pays upfront (held in escrow)
2. **Task Assignment**: Worker accepts task
3. **Work Completion**: Worker completes assigned work
4. **Verification**: Landlord confirms completion
5. **Payment Release**: System releases payment to worker
6. **Mutual Rating**: Both parties rate each other

### **Aadhar Verification System**
**User Profile Extension:**
- `isAadharVerified` boolean field
- `aadharNumber` (encrypted/secured)
- `aadharVerificationDate`

**Verification Process:**
1. Input Aadhar number
2. Send OTP to registered mobile (mocked initially)
3. Verify OTP
4. Mark user as verified
5. Store only verification status (not full details)

**Security Considerations:**
- Never store complete Aadhar details
- Only verification status stored
- Proper encryption implementation
- Regulatory compliance consideration

## 🏗️ Project Architecture

```
lib/
├── main.dart                      # App entry point
├── screens/
│   ├── splash_screen.dart         # App launch screen
│   ├── selection_page.dart        # Role selection
│   ├── farmer_auth_screen.dart    # Farmer authentication
│   ├── vendor_auth_screen.dart    # Vendor authentication
│   ├── farmer_dashboard_screen.dart # Farmer main dashboard
│   ├── vendor_dashboard_screen.dart # Vendor main dashboard
│   ├── farmer_work_dashboard.dart  # Work management (Phase 2)
│   ├── request_worker_screen.dart  # Worker request form
│   ├── my_requests_screen.dart     # Request management
│   ├── available_tasks_screen.dart # Available tasks for workers
│   ├── task_detail_screen.dart     # Individual task details
│   └── add_product_screen.dart     # Product addition
├── services/
│   ├── location_service.dart       # Location handling
│   ├── auth_service.dart          # Authentication logic
│   ├── payment_service.dart       # Payment processing
│   └── notification_service.dart   # Push notifications
├── models/                        # Data models
├── widgets/                       # Reusable UI components
└── utils/                         # Helper functions
```

## 🔧 Installation & Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase account
- Razorpay account
- Git

### Hardware Requirements
**Minimum:**
- Intel Core i5 processor
- 8GB RAM
- 256GB SSD

**Recommended:**
- Intel Core i7/i9 or AMD Ryzen 7/9
- 16GB+ RAM
- 512GB+ SSD

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/DeepakGowda123/College-Project.git
   cd College-Project
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a new Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in respective directories
   - Enable Authentication, Firestore, and Storage

4. **API Keys Setup**
   - Copy `lib/config/api_keys.example.dart` to `lib/config/api_keys.dart`
   - Replace placeholder values with your actual API keys:
     - Razorpay API key
     - OpenWeather API key
     - Google Maps API key (if used)

5. **Run the application**
   ```bash
   flutter run
   ```

## 📊 Database Structure

### Firestore Collections

```
users/
├── {userId}/
│   ├── role: "farmer" | "vendor" | "landlord" | "worker"
│   ├── email: string
│   ├── isAadharVerified: boolean
│   └── profile: object

products/
├── {productId}/
│   ├── vendorId: string
│   ├── name: string
│   ├── category: string
│   ├── price: number
│   └── stock: number

orders/
├── {orderId}/
│   ├── farmerId: string
│   ├── vendorId: string
│   ├── items: array
│   ├── status: string
│   └── paymentStatus: string

workRequests/
├── {requestId}/
│   ├── landlordId: string
│   ├── workType: string
│   ├── payment: number
│   ├── status: string
│   └── escrowStatus: string

notifications/
├── {notificationId}/
│   ├── userId: string
│   ├── title: string
│   ├── message: string
│   └── read: boolean
```

## 🌟 Key Algorithms

### **Dynamic Pricing Algorithm**
- Work type and duration-based pricing
- Gender-specific rates (as per market standards)
- Custom hour calculation: `price = hourly_rate × hours`

### **Worker Matching Algorithm**
- Location-based proximity matching
- Skill and availability filtering
- Automatic request forwarding system

### **Escrow Payment System**
- Secure payment holding mechanism
- Automatic release upon task completion
- Dispute resolution workflow

## 🚀 Implementation Roadmap

### Phase 1 Status: ✅ Complete
- [x] User authentication system
- [x] Farmer-Vendor commerce platform
- [x] Product catalog and cart system
- [x] Order processing and tracking
- [x] Payment integration
- [x] Notification system
- [x] Weather integration

### Phase 2 Status: ✅ Complete
- [x] Landlord-Worker hiring system
- [x] Aadhar verification system
- [x] Escrow payment mechanism
- [x] Task management workflow
- [x] Rating and review system
- [x] Advanced location services

## 📈 Future Enhancements

- **Multi-language Support**: Regional languages (Kannada, Hindi, Telugu)
- **Voice Assistance**: Voice-guided navigation for elderly users
- **AI Recommendations**: Smart inventory and pricing suggestions
- **Government Integration**: Subsidies and agricultural scheme information
- **Advanced Analytics**: Seasonal trends and cost analysis
- **Microloan Services**: UPI-based financial services
- **IoT Integration**: Smart farming equipment connectivity

## 🧪 Testing

### Test Credentials
- **Razorpay Test UPI**: success@razorpay
- **Mock Aadhar OTP**: 123456
- **Test Weather API**: OpenWeather sandbox

## 🤝 Contributing

This project was developed as part of MCA capstone project at PES University, Bengaluru. The codebase demonstrates:

- **Clean Architecture**: Separation of concerns
- **Scalable Design**: Modular component structure
- **Security Best Practices**: Secure authentication and payment handling
- **Real-world Problem Solving**: Addressing actual agricultural challenges

## 📝 License

This project is developed for educational and portfolio purposes.

## 👨‍💻 Developer

**Deepak A S**
- MCA Student, PES University, Bengaluru (2024-2025)
- 📧 Email: deepak.gowda1215@gmail.com
- 💼 LinkedIn: https://www.linkedin.com/in/deepak-a-s-7a2aa3264/
- 🌐 GitHub: https://github.com/DeepakGowda123
- 📱 Mobile: +91 8792025278

## 📞 Contact

For any queries regarding this project, please reach out via email or LinkedIn.

---

*Built with ❤️ for the agricultural community*

> **Note**: This is a comprehensive agricultural platform addressing real-world challenges in rural India. The project demonstrates full-stack mobile development skills with modern technologies and best practices.
