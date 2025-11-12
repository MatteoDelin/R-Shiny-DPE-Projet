# Application d'Analyse des DPE du Département de l'Ain (01)

> **Tableau de bord interactif** pour analyser et visualiser les Diagnostics de Performance Énergétique (DPE) des logements du département de l'Ain dans le cadre de la sobriété énergétique.

---

## Table des Matières

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

## À Propos

### Contexte du Projet

Cette application a été développée par **GreenTech Solutions** pour **ENEDIS** dans le cadre d'une étude sur l'impact des classes de Diagnostic de Performance Énergétique (DPE) sur les consommations électriques des logements.

Avec l'accélération du changement climatique et la hausse des prix de l'énergie, la sobriété énergétique est au cœur des préoccupations des Français. Cette application permet d'identifier les **passoires énergétiques** (étiquettes F et G) et d'analyser les facteurs influençant la performance énergétique des bâtiments.

### Objectifs

- Visualiser la répartition des étiquettes DPE dans le département de l'Ain
- Cartographier les logements selon leur performance énergétique
- Identifier les zones à forte concentration de passoires énergétiques
- Analyser les corrélations entre variables énergétiques
- Fournir des données exploitables pour la transition énergétique

### Source des Données

Les données proviennent de l'**ADEME** (Agence de l'Environnement et de la Maîtrise de l'Énergie) :
- [API DPE v2 - Logements existants](https://data.ademe.fr/datasets/dpe-v2-logements-existants)
- [API DPE v2 - Logements neufs](https://data.ademe.fr/datasets/dpe-v2-logements-neufs)

---

## Fonctionnalités

### Niveau Standard
- Tableau de bord avec **5 onglets thématiques**
- **KPI dynamiques** : nombre de logements, surface moyenne, qualité d'isolation
- **4 types de graphiques interactifs** : histogramme, barres, boxplot, nuage de points
- **Carte interactive Leaflet** avec clustering des marqueurs
- **Filtres multi-critères** : dates, surface, étiquette, type de bâtiment, énergie...
- **Tableau de données** avec recherche, tri et pagination
- Page **Contexte** avec informations détaillées

### Niveau Intermédiaire
- **12 thèmes visuels** personnalisables (bleu, noir, violet, vert, rouge, jaune + variantes claires)
- **Export des graphiques** en PNG haute résolution (300 DPI)
- **Export des données** filtrées en CSV
- **Calcul du coefficient de corrélation** entre variables numériques
- **Régression linéaire simple** avec droite de tendance

### Niveau Expert
- **Charte graphique CSS** personnalisée
- **Authentification utilisateur** avec mots de passe hashés (Argon2)
- **Rafraîchissement automatique** des données via l'API ADEME
- Mise à jour **incrémentale** des DPE (pas de doublons)

---

## Démo

### Application en Ligne
**URL de déploiement** : `https://[votre-compte].shinyapps.io/dpe-ain-01/`

### Vidéo de Démonstration
**YouTube** : [Lien vers la vidéo privée]

### Structure du Projet

```
│
├── app/                              # Code source de l’application Shiny
│   ├── app.R                         # Fichier principal Shiny (ou ui.R + server.R)
│   ├── www/                          # Ressources statiques (images, icônes)
│   │   ├── logo.png
│   └── data/                         # Données locales accessibles à l’app
│       ├── dpe_clean.csv
│
├── data_preparation/                 # Scripts de préparation et d’analyse des données
│   ├── extraction_api.R
│
├── rapport/                             
│   ├── rapport_statistique.Rmd              le script de votre rapport Rmarkdown
│   ├── rapport_statistique.html/pdf           la version "knit" en HTML ou pdf (4 à 6 pages environ)
|
├── docs/                             # Documentation du projet
│   ├── technical_doc.md              # Documentation technique (2 pages max)
│   ├── functional_doc.md             # Documentation fonctionnelle (2 pages max)
└── README.md   # README principal du dépôt avec le lien de la vidéo démo et de la démo déployé.

└── .gitignore                  # Fichiers à ignorer (CSV volumineux)
```

## Documentation

### Documents Disponibles

| Document                 | Description                        | Public cible          |
|--------------------------|------------------------------------|-----------------------|
| [README.md]              | Vue d'ensemble du projet           | Tous                  |
| [doc_fonctionnelle.md]   | Guide utilisateur complet          | Utilisateurs finaux   |
| [doc_technique.md]       | Détails techniques et architecture | Développeurs          |

### Ressources Externes

- [Documentation Shiny](https://shiny.posit.co/)
- [Leaflet pour R](https://rstudio.github.io/leaflet/)
- [Plotly R](https://plotly.com/r/)
- [shinyauthr Guide](https://github.com/PaulC91/shinyauthr)
- [sf Package](https://r-spatial.github.io/sf/)

---

## Contributeurs

### Équipe GreenTech Solutions

| Nom       | Prénom |
|-----------|--------|
| Delin     | Mattéo |
| Margerand | Timéo  |

### Client

- **ENEDIS** - Demandeur du projet

---

<div align="center">

⭐ **N'hésitez pas à donner une étoile si ce projet vous plaît !** ⭐

</div>