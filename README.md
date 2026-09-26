# ForFood

**Budget-first food discovery for restaurants and diners.**

Find meals near you that fit your budget — from restaurants that deliver or offer pickup. Order, track, and chat with the restaurant in one app.

Built solo by **Zekkour Ritadj** for [RevenueCat Shipaton 2026](https://revenuecat-shipaton-2026.devpost.com/) — **Next Gen Award** (student category).

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Demo video

🎬 **[Watch the demo](https://www.youtube.com/watch?v=T9x12rNwpqE)**

---

## What it does

ForFood is a two-sided marketplace:

- **Diners** search by craving, budget, and location. Results are ranked cheapest-first, then by distance, then by rating — so people on a tight budget actually find a meal they can afford. They add items to a single-restaurant cart and check out for delivery or pickup.
- **Restaurants** manage their menu, accept or reject incoming orders, progress them through the kitchen workflow, chat with customers, and view live stats (orders, revenue, ratings, top items).

The differentiator is the **budget-first search**: instead of ranking by rating or sponsored placement, ForFood sorts primarily by price. This serves users who need an affordable meal nearby.

---

## RevenueCat integration

The restaurant subscription tier is powered by the **RevenueCat SDK** (`purchases_flutter`). Restaurants get a 6-month free trial, then choose between $5/mo or $40/yr.

- Entitlement: `premium`
- Offerings: `default` (monthly + yearly packages)
- Sandbox: RevenueCat **Test Store** (for judge testing without a store release)
- Config: `lib/service/revenuecat/revenuecat_service.dart`
- Subscriber identification: `Purchases.logIn(uid)` is called on login

Because this is a **Next Gen Award** submission, the app is distributed via source + video rather than the App Store or Play Store. RevenueCat is configured against the Test Store so judges can see a working paywall and purchase flow on camera.

---

## Features

### For diners
- Email-verified signup
- Budget-first search: craving + max budget + location
- Nearby restaurants via geohash-based spatial query
- Smart search ranking: matches "pizzas" to "pizza", tolerates typos, handles multi-word cravings
- Single-restaurant cart with quantity steppers
- Pickup or delivery checkout with saved addresses
- Live order tracking: pending → accepted → preparing → ready / out for delivery → completed
- In-order chat with the restaurant (swipe to delete your own messages)
- Push notifications for every order state change (swipe to delete, or clear all)
- Reviews with 1–5 stars
- "Your usual" — one-tap reorder of your most repeated order

### For restaurants
- Onboarding with map-picked address
- Menu management (add, edit, delete, images)
- Gallery of food photos
- Incoming orders inbox with accept/reject
- Order status progression with prep-time estimation
- Statistics dashboard: views, orders, revenue, rating, top items
- Chat with customers
- RevenueCat-powered subscription tier

### Cross-cutting
- English / Arabic / French localization
- Haptic feedback on primary actions
- Skeleton loaders on every list
- Responsive layout (scales from small phones to tablets)
- Disk-cached map tiles and images

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart 3.10) |
| State management | `flutter_bloc` |
| Auth | Firebase Auth (email verification) |
| Database | Cloud Firestore (real-time listeners) |
| Storage | Firebase Storage + ImgBB for image hosting |
| Push | Firebase Cloud Messaging |
| Maps | `flutter_map` + Geoapify tiles + OpenStreetMap |
| Map caching | `flutter_map_cache` + Hive |
| Geocoding | Nominatim (OpenStreetMap) |
| Routing | OSRM (driving directions) |
| Location | `geolocator` + `flutter_compass` |
| Subscriptions | **RevenueCat** (`purchases_flutter`) |
| Image caching | `cached_network_image` |
| Charts | `fl_chart` |
| i18n | `flutter_localizations` + `intl` |
| Image picking | `image_picker` |

---

## Architecture
