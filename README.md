# ForFood

**Budget-first food discovery for restaurants and diners.**

Find meals near you that fit your budget — from restaurants that deliver or offer pickup. Order, track, and chat with the restaurant in one app.

Built solo by **Zekkour Ritadj** for [RevenueCat Shipaton 2026](https://revenuecat-shipaton-2026.devpost.com/) — **Next Gen Award** (student category).

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Demo video

🎬 **[Watch the 2-minute demo](TODO_ADD_YOUTUBE_LINK_HERE)**

---

## What it does

ForFood is a two-sided marketplace:

- **Diners** search by craving, budget, and location. They get ranked results (cheapest → nearest → best-rated), add items to a single-restaurant cart, and check out for delivery or pickup.
- **Restaurants** manage their menu, accept or reject orders, progress them through the kitchen workflow, chat with customers, and see live stats (orders, revenue, ratings, top items).

The differentiator is the **budget-first search**: instead of ranking by rating or featured placement, ForFood sorts primarily by price, then proximity, then rating — so the app actually serves people who need a cheap meal near them.

---

## RevenueCat integration

The restaurant subscription tier is powered by the **RevenueCat SDK** (`purchases_flutter`). Restaurants get a 6-month free trial, then choose between $5/mo or $40/yr.

- Entitlement: `premium`
- Offerings: `default` (monthly + yearly packages)
- Sandbox: RevenueCat Test Store (for judge testing without a store release)
- Config: `lib/service/revenuecat/revenuecat_service.dart`

Because this is a **Next Gen** submission, the app is distributed via source + video, not the App Store or Play Store. RevenueCat is configured against the Test Store so judges can see a working paywall and purchase flow on camera.

---

## Features

### For diners
- Email-verified signup
- Budget-first search: craving + max budget + location
- Nearby restaurants via geohash-based spatial query
- Single-restaurant cart with quantity steppers
- Pickup or delivery checkout with saved addresses
- Live order tracking: pending → accepted → preparing → ready/out-for-delivery → completed
- In-order chat with the restaurant
- Push notifications on every order state change
- Reviews with 1–5 stars

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
- Responsive layout
- Dark-mode-ready color system

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart 3.10) |
| State management | `flutter_bloc` |
| Auth | Firebase Auth |
| Database | Cloud Firestore |
| Storage | Firebase Storage + ImgBB |
| Push | Firebase Cloud Messaging |
| Maps | `flutter_map` + Geoapify + OpenStreetMap |
| Geocoding | Nominatim |
| Routing | OSRM |
| Location | `geolocator` + `flutter_compass` |
| Subscriptions | **RevenueCat** |
| Charts | `fl_chart` |
| i18n | `flutter_localizations` + `intl` |

---

## Architecture
