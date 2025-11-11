# 🏠 Application d'Analyse des DPE du Département de l'Ain (01)

[![Shiny](https://img.shields.io/badge/Shiny-Dashboard-blue?style=flat&logo=r)](https://shiny.posit.co/)
[![R Version](https://img.shields.io/badge/R-%E2%89%A5%204.0.0-276DC3?style=flat&logo=r)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production-success)](https://www.shinyapps.io/)

> 📊 **Tableau de bord interactif** pour analyser et visualiser les Diagnostics de Performance Énergétique (DPE) des logements du département de l'Ain dans le cadre de la sobriété énergétique.

---

## 📋 Table des Matières

- [À Propos](#-à-propos)
- [Fonctionnalités](#-fonctionnalités)
- [Démo](#-démo)
- [Installation](#-installation)
- [Utilisation](#-utilisation)
- [Architecture](#-architecture)
- [Technologies](#-technologies)
- [Documentation](#-documentation)
- [Contributeurs](#-contributeurs)
- [Licence](#-licence)

---

## 🎯 À Propos

### Contexte du Projet

Cette application a été développée par **GreenTech Solutions** pour **ENEDIS** dans le cadre d'une étude sur l'impact des classes de Diagnostic de Performance Énergétique (DPE) sur les consommations électriques des logements.

Avec l'accélération du changement climatique et la hausse des prix de l'énergie, la sobriété énergétique est au cœur des préoccupations des Français. Cette application permet d'identifier les **passoires énergétiques** (étiquettes F et G) et d'analyser les facteurs influençant la performance énergétique des bâtiments.

### Objectifs

- ✅ Visualiser la répartition des étiquettes DPE dans le département de l'Ain
- ✅ Cartographier les logements selon leur performance énergétique
- ✅ Identifier les zones à forte concentration de passoires énergétiques
- ✅ Analyser les corrélations entre variables énergétiques
- ✅ Fournir des données exploitables pour la transition énergétique

### Source des Données

Les données proviennent de l'**ADEME** (Agence de l'Environnement et de la Maîtrise de l'Énergie) :
- 🔗 [API DPE v2 - Logements existants](https://data.ademe.fr/datasets/dpe-v2-logements-existants)
- 🔗 [API DPE v2 - Logements neufs](https://data.ademe.fr/datasets/dpe-v2-logements-neufs)

---

## ✨ Fonctionnalités

### 🎨 Niveau Standard
- ✅ Tableau de bord avec **5 onglets thématiques**
- ✅ **KPI dynamiques** : nombre de logements, surface moyenne, qualité d'isolation
- ✅ **4 types de graphiques interactifs** : histogramme, barres, boxplot, nuage de points
- ✅ **Carte interactive Leaflet** avec clustering des marqueurs
- ✅ **Filtres multi-critères** : dates, surface, étiquette, type de bâtiment, énergie...
- ✅ **Tableau de données** avec recherche, tri et pagination
- ✅ Page **Contexte** avec informations détaillées

### 🚀 Niveau Intermédiaire
- ✅ **12 thèmes visuels** personnalisables (bleu, noir, violet, vert, rouge, jaune + variantes claires)
- ✅ **Export des graphiques** en PNG haute résolution (300 DPI)
- ✅ **Export des données** filtrées en CSV
- ✅ **Calcul du coefficient de corrélation** entre variables numériques
- ✅ **Régression linéaire simple** avec droite de tendance

### 🔥 Niveau Expert
- ✅ **Charte graphique CSS** personnalisée
- ✅ **Authentification utilisateur** avec mots de passe hashés (Argon2)
- ✅ **Rafraîchissement automatique** des données via l'API ADEME
- ✅ Mise à jour **incrémentale** des DPE (pas de doublons)

---

## 🎬 Démo

### Application en Ligne
🌐 **URL de déploiement** : `https://[votre-compte].shinyapps.io/dpe-ain-01/`

### Vidéo de Démonstration
📹 **YouTube** : [Lien vers la vidéo privée] *(5 min)*

### Captures d'Écran

**Page Graphiques - KPI et Visualisations**
```
┌─────────────────────────────────────────────────────┐
│  📊 Logements DPE     🏠 Surface moyenne     🛡️ Isolation │
│       45,823              87 m²             23.5%    │
└─────────────────────────────────────────────────────┘
```

**Carte Interactive - Clustering des Logements**
```
┌─────────────────────────────────────────────────────┐
│                    🗺️ Carte Leaflet                   │
│  • Markers regroupés par zone géographique          │
│  • Popup : Adresse, Étiquette DPE, Consommation     │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Installation

### Prérequis

- **R** version ≥ 4.0.0
- **RStudio** (recommandé)
- Connexion Internet pour l'API ADEME

### Cloner le Repository

```bash
git clone https://github.com/[votre-username]/iut_sd2_rshiny_enedis.git
cd iut_sd2_rshiny_enedis
```

### Installer les Packages R

Ouvrez RStudio et exécutez :

```r
install.packages(c(
  "shiny", "leaflet", "bslib", "ggplot2", "DT", "dplyr", 
  "plotly", "sf", "shinydashboard", "thematic", "httr", 
  "jsonlite", "shinyjs", "shinyauthr", "sodium", "lubridate"
))
```

### Structure du Projet

```
iut_sd2_rshiny_enedis/
│
├── app.R                       # Application Shiny principale
├── BaseDeDonnes.csv            # Données DPE (non versionnées si volumineuses)
├── www/
│   └── style.css               # Charte graphique personnalisée
│
├── README.md                   # Ce fichier
├── doc_fonctionnelle.md        # Documentation utilisateur
├── doc_technique.md            # Documentation développeur
│
└── .gitignore                  # Fichiers à ignorer (CSV volumineux)
```

---

## 🚀 Utilisation

### Lancer l'Application en Local

**Méthode 1 : Via RStudio**
1. Ouvrir `app.R` dans RStudio
2. Cliquer sur le bouton **"Run App"** (en haut à droite)
3. L'application s'ouvre dans un navigateur ou une fenêtre RStudio

**Méthode 2 : Via la Console R**
```r
shiny::runApp("app.R")
```

### Connexion à l'Application

L'application nécessite une authentification :

| Utilisateur | Mot de passe | Permissions |
|-------------|--------------|-------------|
| `admin` | `admin` | Administrateur |
| `user` | `Timeo X Mommy` | Utilisateur standard |

### Navigation

1. **Graphiques** 📊 : Visualisations interactives et KPI
2. **Cartographie** 🗺️ : Carte des logements DPE
3. **Tableaux** 📋 : Export et filtrage des données
4. **Filtres** 🔍 : Personnalisation des analyses
5. **Contexte** ℹ️ : Informations et documentation

### Fonctionnalités Clés

#### Filtrer les Données
1. Aller dans l'onglet **"Filtres"**
2. Sélectionner les critères (dates, surface, étiquette...)
3. Cliquer sur **"Appliquer les filtres"**
4. Tous les graphiques et tableaux se mettent à jour automatiquement

#### Analyser une Corrélation
1. Aller dans l'onglet **"Graphiques"**
2. Faire défiler jusqu'au **nuage de points**
3. Sélectionner une variable X et une variable Y
4. Observer le coefficient de corrélation et la droite de régression

#### Rafraîchir les Données
1. Aller dans l'onglet **"Tableaux"**
2. Cliquer sur **"Rafraîchir les données (API)"**
3. L'application interroge l'API ADEME et ajoute les nouveaux DPE

#### Exporter les Résultats
- **Graphiques** : Cliquer sur les boutons "Exporter en PNG" sous chaque graphique
- **Données** : Cliquer sur "Exporter en CSV" dans l'onglet "Tableaux"

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  INTERFACE UTILISATEUR                    │
│         (Shiny UI - shinydashboard + shinyauthr)         │
└─────────────────────┬────────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          │                       │
    ┌─────▼─────┐          ┌──────▼──────┐
    │ Authentif.│          │   Serveur   │
    │ (sodium)  │          │  (Reactive) │
    └───────────┘          └──────┬──────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
              ┌─────▼─────┐              ┌──────▼──────┐
              │ Data Layer│              │ Visualisation│
              │(reactiveVal)│            │ (plotly/leaflet)│
              └─────┬─────┘              └─────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
    ┌─────▼─────┐      ┌──────▼──────┐
    │ CSV Local │      │ API ADEME   │
    └───────────┘      └─────────────┘
```

### Technologies Utilisées

**Backend**
- `shiny` : Framework web réactif
- `dplyr` : Manipulation de données
- `sf` : Géospatial (Lambert-93 → WGS84)
- `httr` + `jsonlite` : Communication avec l'API ADEME
- `shinyauthr` + `sodium` : Authentification sécurisée

**Frontend**
- `shinydashboard` : Template de tableau de bord
- `bslib` : Thèmes Bootstrap personnalisables
- `shinyjs` : Intégration JavaScript
- `leaflet` : Cartographie interactive
- `plotly` : Graphiques interactifs
- `DT` : Tableaux de données avancés

**Visualisation**
- `ggplot2` : Grammaire des graphiques
- `plotly` : Conversion interactive
- `thematic` : Cohérence des thèmes

---

## 📚 Documentation

### Documents Disponibles

| Document | Description | Public cible |
|----------|-------------|--------------|
| [README.md](README.md) | Vue d'ensemble du projet | Tous |
| [doc_fonctionnelle.md](doc_fonctionnelle.md) | Guide utilisateur complet | Utilisateurs finaux |
| [doc_technique.md](doc_technique.md) | Détails techniques et architecture | Développeurs |

### Ressources Externes

- 📖 [Documentation Shiny](https://shiny.posit.co/)
- 🗺️ [Leaflet pour R](https://rstudio.github.io/leaflet/)
- 📊 [Plotly R](https://plotly.com/r/)
- 🔐 [shinyauthr Guide](https://github.com/PaulC91/shinyauthr)
- 🌍 [sf Package](https://r-spatial.github.io/sf/)

---

## 👥 Contributeurs

### Équipe GreenTech Solutions

| Rôle | Nom | Responsabilités |
|------|-----|-----------------|
| 👨‍💼 Chef de Projet | [Nom] | Planification, coordination, gestion client |
| 👨‍💻 Développeur | [Nom] | Développement back-end/front-end, déploiement |
| 📊 Data Scientist | [Nom] | Analyse statistique, visualisations, modélisation |

### Client

- **ENEDIS** - Demandeur du projet
- **Anthony** - Représentant client

---

## 📊 Statistiques du Projet

- **Lignes de code** : ~1500 lignes (R + CSS + JS)
- **Packages utilisés** : 16
- **Sources de données** : 2 APIs ADEME + 1 CSV local
- **Période couverte** : 2021 - 2025
- **Nombre de DPE** : ~45 000+ (Ain uniquement)
- **Fonctionnalités** : 30+

---

## 🐛 Problèmes Connus et Limitations

### Limitations Techniques

- **Volume maximal** : ~100 000 lignes (limite shinyapps.io gratuit)
- **Timeout API** : Requêtes limitées à 10 secondes
- **Mémoire** : 1 GB sur shinyapps.io (plan gratuit)
- **Département** : Données uniquement pour l'Ain (01)

### Bugs Connus

Aucun bug majeur identifié à ce jour. Pour signaler un problème :
1. Ouvrir une **Issue** sur GitHub
2. Décrire le comportement attendu vs observé
3. Joindre des captures d'écran si possible

---

## 🔄 Roadmap et Améliorations Futures

### Version 1.1 (Prévue)
- [ ] Support multi-départements
- [ ] Comparaison avant/après rénovation énergétique
- [ ] Export PDF des rapports personnalisés
- [ ] Prédiction de l'étiquette DPE avec ML

### Version 2.0 (Long terme)
- [ ] Module d'administration pour gérer les utilisateurs
- [ ] Intégration avec d'autres sources de données (météo, prix de l'énergie)
- [ ] Dashboard temps réel avec actualisation automatique
- [ ] API REST pour exposer les statistiques

---

## 📝 Changelog

### Version 1.0.0 (Novembre 2025)
- ✅ Release initiale
- ✅ Authentification avec shinyauthr
- ✅ 5 onglets fonctionnels
- ✅ 12 thèmes personnalisables
- ✅ Export CSV et PNG
- ✅ Rafraîchissement via API ADEME
- ✅ Cartographie interactive
- ✅ Régression linéaire et corrélation

---

## 📄 Licence

Ce projet est sous licence **MIT**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

```
MIT License

Copyright (c) 2025 GreenTech Solutions

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 🙏 Remerciements

- **ENEDIS** pour la confiance accordée
- **ADEME** pour la mise à disposition des données publiques
- **IUT SD2** pour l'encadrement pédagogique
- **Communauté R Shiny** pour les ressources et packages

---

## 📧 Contact

Pour toute question ou suggestion :

- 📧 **Email** : contact@greentech-solutions.fr
- 💼 **GitHub** : [github.com/[votre-username]/iut_sd2_rshiny_enedis](https://github.com/[votre-username]/iut_sd2_rshiny_enedis)
- 🐦 **Twitter** : @GreenTechSol

---

<div align="center">

**Fait avec ❤️ par GreenTech Solutions**

⭐ **N'hésitez pas à donner une étoile si ce projet vous plaît !** ⭐

</div>