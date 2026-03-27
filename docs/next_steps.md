# Prochaines Étapes - Uprising Cockpit v1.1.1

Ce document détaille les améliorations futures et les tâches de maintenance suite à la refonte "Liquid Glass" et la stabilisation de la v1.1.1.

## 🚀 Fonctionnalités à Venir

### 1. Planification & Calendrier (Calendar)
- [ ] **Détails de Réservation** : Finaliser la page `booking_detail_screen.dart` pour permettre l'édition des rendez-vous.
- [ ] **Synchronisation Google Calendar** : Ajouter l'intégration bidirectionnelle pour les techniciens.
- [ ] **Vues avancées** : Ajouter une vue "Semaine" et "Liste" plus immersive avec des effets de flou directionnel.

### 2. Intelligence Artificielle (Bland AI)
- [ ] **Historique des Appels** : Intégrer la lecture des transcriptions Bland AI directement dans la "Fiche Client".
- [ ] **Personnalisation de la Voix** : Permettre au business de choisir entre différentes voix IA via les réglages.
- [ ] **Analyse de Sentiment** : Afficher un score de satisfaction client basé sur l'appel IA dans le Cockpit.

### 3. Cartographie & Logistique
- [ ] **Optimisation de Trajet** : Intégrer un moteur de routage pour optimiser les déplacements entre les leads "Urgences".
- [ ] **Clusters de Markers** : Si le nombre de leads augmente, implémenter le clustering sur `FlutterMap`.

## 🛠️ Améliorations Techniques

### 1. Stabilité & Performance
- [ ] **HomeWidget Progressif** : Tester les widgets natifs (iOS/Android) sur de vrais appareils pour s'assurer que les données `savings` se mettent à jour correctement.
- [ ] **Shadow Dom / Repaint Boundaries** : Optimiser les performances des `GlassCard` (BackdropFilter) sur les appareils d'entrée de gamme.
- [ ] **Migration Clean Architecture** : Séparer davantage les couches de présentation et de repository pour les tests unitaires.

### 2. Design System
- [ ] **Dark Mode Premium** : Concevoir une version "Obsidian" du thème pour le mode sombre.
- [ ] **Micro-Interactions Lottie** : Ajouter des animations Lottie pour les états de succès (Invoices payées, Booking validé).

## 📦 Maintenance
- [ ] **Mise à jour des Dépendances** : Passer à `flutter_map` v8+ et `go_router` v17+ (nécessite des ajustements de breaking changes).
- [ ] **Nettoyage du Code** : Supprimer les anciens fichiers de thème inutilisés et les constantes obsolètes.
