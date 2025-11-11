# Documentation Technique
## Application d'Analyse des DPE du Département de l'Ain (01)

---

## 🏗️ Architecture de l'Application

```
┌─────────────────────────────────────────────────────────────┐
│                    INTERFACE UTILISATEUR                     │
│              (Shiny UI - dashboardPage)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼────────┐           ┌────────▼────────┐
│  Authentification│           │  Contenu Principal│
│  (shinyauthr)   │           │  (dashboardBody) │
└───────┬────────┘           └────────┬────────┘
        │                             │
        │              ┌──────────────┴──────────────┐
        │              │                             │
        │     ┌────────▼────────┐          ┌────────▼────────┐
        │     │   SERVEUR R     │          │   DATA LAYER    │
        │     │  (Réactivité)   │◄────────►│  (reactiveValues)│
        │     └────────┬────────┘          └────────┬────────┘
        │              │                            │
        │              │                   ┌────────▼────────┐
        │              │                   │  BaseDeDonnes.csv│
        │              │                   └────────┬────────┘
        │              │                            │
        └──────────────┼────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼────────┐           ┌────────▼────────┐
│   API ADEME    │           │  Leaflet / SF   │
│  (refresh_api) │           │  (Géospatial)   │
└────────────────┘           └─────────────────┘
```

### **Composants Principaux**

1. **UI (Interface)** : dashboardPage avec header, sidebar, body
2. **Serveur** : logique réactive et gestion des événements
3. **Couche Data** : `reactiveValues()` pour stockage temporaire
4. **Sources de données** : CSV local + API ADEME
5. **Modules externes** : authentification, cartographie, visualisation

---

## 📦 Installation et Configuration

### **Prérequis Système**
- **R** : version ≥ 4.0.0
- **RStudio** : version recommandée ≥ 2023.06.0
- **Système d'exploitation** : Windows, macOS, Linux

### **Installation des Packages**

Exécutez cette commande pour installer toutes les dépendances :

```r
install.packages(c(
  "shiny",           # Framework web
  "leaflet",         # Cartographie interactive
  "bslib",           # Thèmes Bootstrap
  "ggplot2",         # Visualisations statiques
  "DT",              # Tableaux interactifs
  "dplyr",           # Manipulation de données
  "plotly",          # Graphiques interactifs
  "sf",              # Données géospatiales
  "shinydashboard",  # Template dashboard
  "thematic",        # Thèmes cohérents
  "httr",            # Requêtes HTTP
  "jsonlite",        # Parsing JSON
  "shinyjs",         # JavaScript dans Shiny
  "shinyauthr",      # Authentification
  "sodium",          # Hachage mot de passe
  "lubridate"        # Gestion des dates
))
```

### **Structure des Fichiers**

```
projet_dpe_ain/
│
├── app.R                    # Application principale
├── BaseDeDonnes.csv         # Données DPE locales
├── www/                     # Ressources statiques
│   └── style.css            # Charte graphique CSS
│
├── README.md                # Présentation du projet
├── doc_fonctionnelle.md     # Documentation utilisateur
└── doc_technique.md         # Documentation développeur
```

### **Fichier de Données Requis**

Le fichier `BaseDeDonnes.csv` doit contenir au minimum ces colonnes :
- `numero_dpe`, `date_etablissement_dpe`, `etiquette_dpe`
- `type_batiment`, `surface_habitable_logement`
- `adresse_ban`, `code_postal_ban`, `code_insee_ban`
- `coordonnee_cartographique_x_ban`, `coordonnee_cartographique_y_ban`
- `conso_5_usages_par_m2_ep`, `cout_total_5_usages`
- `type_energie_n1`, `type_energie_principale_chauffage`
- `qualite_isolation_enveloppe`, `classe_inertie_batiment`

---

## 🚀 Lancement de l'Application

### **En Local (Développement)**

1. **Ouvrir RStudio**
2. **Charger le projet** : File → Open Project → `projet_dpe_ain.Rproj`
3. **Ouvrir app.R**
4. **Cliquer sur "Run App"** ou exécuter :

```r
shiny::runApp("chemin/vers/app.R")
```

5. L'application s'ouvre dans un navigateur ou une fenêtre RStudio

### **Déploiement sur shinyapps.io**

1. **Installer rsconnect** :
```r
install.packages("rsconnect")
```

2. **Configurer le compte** :
```r
rsconnect::setAccountInfo(
  name = "votre_compte",
  token = "votre_token",
  secret = "votre_secret"
)
```

3. **Déployer** :
```r
rsconnect::deployApp(
  appDir = "chemin/vers/projet",
  appName = "dpe-ain-01",
  forceUpdate = TRUE
)
```

4. **URL de l'application** : `https://votre_compte.shinyapps.io/dpe-ain-01/`

---

## 🔧 Architecture Technique Détaillée

### **1. Authentification (shinyauthr)**

**Base d'utilisateurs** :
```r
user_base = tibble(
  user = c("admin", "user"),
  password = sapply(c("admin", "Timeo X Mommy"), sodium::password_store),
  permissions = c("admin", "On le sait"),
  name = c("Administrateur", "Utilisateur")
)
```

**Processus** :
1. `loginUI()` affiche le formulaire de connexion
2. `loginServer()` vérifie les credentials avec hash sodium
3. Si authentifié → `shinyjs::show("app_content")`
4. Bouton déconnexion via `logoutServer()`

---

### **2. Gestion des Données Réactives**

**Structure** :
```r
rv = reactiveValues(data = table_data)
```

**Flux de données** :
1. **Chargement initial** : `extract_data()` lit `BaseDeDonnes.csv`
2. **Conversion de types** : codes postaux/INSEE en `character`
3. **Filtrage** : `observeEvent(input$appliquer_filtres)` met à jour `rv$data`
4. **Propagation** : tous les outputs réagissent automatiquement

**Fonction de filtrage** :
```r
observeEvent(input$appliquer_filtres, {
  data = table_data
  # Filtres numériques (dates, surface)
  # Filtres catégoriels (étiquette, type...)
  rv$data = data  # Mise à jour réactive
})
```

---

### **3. Transformation Géospatiale (sf)**

**Conversion Lambert-93 → WGS84** :
```r
filtre_map = function(df) {
  # Créer un objet sf en Lambert-93 (EPSG:2154)
  sf_data = st_as_sf(df, 
    coords = c("coordonnee_cartographique_x_ban", 
               "coordonnee_cartographique_y_ban"), 
    crs = 2154)
  
  # Transformer en WGS84 (EPSG:4326) pour Leaflet
  sf_data_wgs84 = st_transform(sf_data, crs = 4326)
  
  # Extraire lat/lon
  coords = st_coordinates(sf_data_wgs84)
  df$latitude = coords[, "Y"]
  df$longitude = coords[, "X"]
  
  return(df)
}
```

---

### **4. API ADEME - Rafraîchissement des Données**

**Endpoint** :
- Existants : `https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines`
- Neufs : `https://data.ademe.fr/data-fair/api/v1/datasets/dpe02neuf/lines`

**Paramètres** :
```r
params = list(
  size = 10000,  # Taille de page max
  select = "champs_séparés_par_virgule",
  qs = "code_departement_ban:01 AND date_etablissement_dpe:[DEBUT TO FIN]"
)
```

**Algorithme** :
1. Identifier la date du dernier DPE local
2. Boucler par mois depuis cette date jusqu'à aujourd'hui
3. Requête GET avec `httr::GET()` et `modify_url()`
4. Parser JSON avec `jsonlite::fromJSON()`
5. Concaténer avec `dplyr::bind_rows()`
6. Dédupliquer avec `unique()`

**Optimisation** :
- Pagination automatique
- Pause entre requêtes (`Sys.sleep(0.1)`)
- Gestion des erreurs avec `try-catch`

---

### **5. Visualisations Plotly**

**Conversion ggplot → plotly** :
```r
output$plot_histogramme_conso = renderPlotly({
  p = ggplot(rv$data, aes(x = conso_5_usages_par_m2_ep)) +
    geom_histogram(bins = 30, fill = "#17a2b8") +
    labs(title = "...", x = "...", y = "...") +
    theme_minimal()
  ggplotly(p)  # Rend interactif
})
```

**Avantages** :
- Zoom, pan, hover automatiques
- Export image intégré
- Responsive

---

### **6. Gestion des Thèmes (JavaScript)**

**Sélecteur dans le header** :
```r
selectInput("theme_selector", ...)
```

**Handler JavaScript personnalisé** :
```javascript
Shiny.addCustomMessageHandler('change_skin', function(skin) {
  $('body').removeClass(/\bskin-\S+/g);  // Retirer ancien thème
  $('body').addClass('skin-' + skin);    // Ajouter nouveau
});
```

**Déclenchement côté serveur** :
```r
observeEvent(input$theme_selector, {
  session$sendCustomMessage(type = "change_skin", 
                            message = input$theme_selector)
})
```

---

## 📊 Calculs Statistiques

### **Coefficient de Corrélation**
```r
correlation = cor(data_clean[[input$scatter_x]], 
                   data_clean[[input$scatter_y]], 
                   use = "complete.obs")
```

### **Régression Linéaire Simple**
```r
geom_smooth(method = "lm", se = FALSE, 
            formula = y ~ x, linewidth = 1)
```

### **Box Plot avec Filtrage des Outliers**
```r
if(input$filter_outliers_cout) {
  Q1 = quantile(data$cout_total_5_usages, 0.25, na.rm = TRUE)
  Q3 = quantile(data$cout_total_5_usages, 0.75, na.rm = TRUE)
  IQR = Q3 - Q1
  data = data %>%
    filter(cout >= (Q1 - 1.5*IQR) & cout <= (Q3 + 1.5*IQR))
}
```

---

## 🎨 Charte Graphique (CSS)

**Fichier** : `www/style.css`

**Personnalisations** :
- Couleurs des thèmes (12 variantes)
- Typographie et espacements
- Styles des boutons et valueBox
- Animations et transitions

**Intégration** :
```r
tags$head(
  tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
)
```

---

## 🔒 Sécurité

### **Hachage des Mots de Passe**
- Utilisation de `sodium::password_store()` (Argon2)
- Jamais de stockage en clair

### **Validation des Entrées**
- `req()` pour vérifier les inputs non NULL
- Filtrage avec `dplyr::filter()` pour éviter les injections

### **Gestion des Sessions**
- Déconnexion automatique via `logoutServer()`
- Masquage du contenu avec `shinyjs::hide()`

---

## ⚡ Performance

### **Optimisations Appliquées**
1. **Lazy Loading** : graphiques rendus uniquement si onglet actif
2. **Filtrage en amont** : réduction des données avant visualisation
3. **Cache réactif** : `reactiveValues()` évite les recalculs
4. **Pagination** : tableaux avec `pageLength = 25`

### **Limitations Connues**
- **Volume max** : ~100 000 lignes (limite shinyapps.io gratuit)
- **Timeout API** : 10 secondes par requête
- **Mémoire** : 1 GB sur shinyapps.io

---

## 🐛 Debugging

### **Logs dans la Console**
```r
print(paste0("Filtrage : ", nrow(data), " lignes"))
```

### **Messages de Notification**
```r
showNotification("Message", type = "message", duration = 5)
```

### **Breakpoints RStudio**
- Cliquer sur la marge gauche de l'éditeur
- Lancer en mode debug : `runApp(launch.browser = FALSE)`

---

## 🧪 Tests

### **Tests Manuels Recommandés**
1. Authentification avec bons/mauvais identifiants
2. Filtrage avec combinaisons multiples
3. Export CSV/PNG
4. Rafraîchissement API avec nouvelles données
5. Changement de thème
6. Responsive design (mobile, tablette, desktop)

---

## 📚 Ressources et Références

- **Shiny** : https://shiny.posit.co/
- **Leaflet pour R** : https://rstudio.github.io/leaflet/
- **API ADEME** : https://data.ademe.fr/
- **dplyr** : https://dplyr.tidyverse.org/
- **plotly** : https://plotly.com/r/

---

## 🔄 Maintenance

### **Mise à Jour de l'Application**
1. Modifier `app.R`
2. Tester en local
3. Redéployer sur shinyapps.io

### **Ajout de Nouvelles Fonctionnalités**
1. Créer un nouvel onglet dans `tabItems()`
2. Ajouter le `menuItem()` correspondant
3. Implémenter les outputs dans le serveur

### **Monitoring**
- Consulter les logs sur shinyapps.io
- Vérifier les temps de chargement
- Analyser les erreurs utilisateurs

---

**Version** : 1.0  
**Dernière mise à jour** : Novembre 2025  
**Développeurs** : GreenTech Solutions  
**Contact technique** : Repository GitHub