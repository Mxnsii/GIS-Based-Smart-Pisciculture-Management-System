# GIS-Based Smart Pisciculture Management System 🐟🛰️

A state-of-the-art Flutter and Leaflet-based GIS aquaculture platform for fish farmers and coastal authorities. Enables real-time IoT water monitoring, active farm registration, AI-powered species recommendation, environmental risk zoning, and environmental complaint hot-spot mapping.

---

## 🚀 Key Features

### 📍 GIS Map & Coastal Monitoring
* **Color-Coded Farm Markers**: Displays registered farms pinned dynamically on both web and mobile platforms. Markers are color-coded based on active state:
  * 🟢 **Green** for Active
  * 🟡 **Orange** for Pending Approval
  * 🔴 **Red** for Rejected
  * ⚫ **Grey** for Inactive
* **Integrated View Details Navigation**: Clicking a farm marker popup allows authorities or owners to click **"View Details"** to navigate directly to the detailed farm insights screen.
* **Coordinate Verification**: Displays highly precise 5-decimal coordinates `(Latitude, Longitude)` inside marker popups, enabling authorities to easily inspect, locate, and verify farm positions relative to environmental zones.
* **🛰️ Satellite View Base Map**: A togglable base layer featuring ESRI high-resolution World Imagery, fully integrated in Leaflet alongside OpenStreetMap.
* **Environmental Overlay Tree**: Toggle salinity zones, sea cage suitability zones, bathymetry (ocean depth), and seawater velocity maps on/off.

### 🚨 Environmental Hotspots & Complaints
* **Pulse Animated Clusters**: Visualizes environmental violation complaints in glowing clusters that pulse dynamically using CSS micro-animations.
* **Interactive Siren Pins (`🚨`)**: Pins individual environmental complaints as animated glowing siren markers.
* **Evidence Image Popups**: Click any complaint to view base64 evidence images uploaded by the reporter alongside detailed descriptions of the suspicious activity.

### 📈 IoT Monitoring & Speedometer Gauges
* Real-time sensor streaming powered by **Firebase Realtime Database** (`/sensors`).
* Responsive radial speedometer gauges tracking:
  * **Temperature (°C)**
  * **pH Levels**
  * **Turbidity (NTU)**
  * **TDS (ppm)**
  * **Salinity (ppt)**
* **Scrolling Historical Trend Charts**: Maintains an in-memory rolling history buffer of live database updates to plot scrolling linear trends.

---

## 🛠️ Technology Stack
* **Frontend**: Flutter (Dart) & Custom HTML5/CSS3/JavaScript
* **Mapping Library**: Leaflet GIS Engine
* **Database**: Google Firebase Firestore (Farms, Complaints, User Accounts) & Firebase Realtime Database (IoT Sensor Streams)
* **API Services**: Nominatim OpenStreetMap API (Geolocation & Reverse Geocoding) & Esri World Imagery (Satellite tiles)
