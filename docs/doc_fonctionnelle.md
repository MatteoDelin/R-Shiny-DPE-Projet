# Documentation Fonctionnelle
## Application d'Analyse des DPE du Département de l'Ain (01)

---

## Présentation de l'Application

Cette application web interactive permet d'analyser et de visualiser les **Diagnostics de Performance Énergétique (DPE)** des logements du département de l'Ain. Elle s'inscrit dans une démarche de sobriété énergétique et aide à identifier les passoires énergétiques pour mieux comprendre l'impact des classes DPE sur les consommations électriques.

**Contexte** : Développée pour ENEDIS par GreenTech Solutions, cette application exploite les données publiques de l'ADEME sur les DPE des logements neufs et existants.

---

## Connexion à l'Application

L'application nécessite une authentification pour garantir la sécurité des données.

**Identifiants disponibles** :
- **Administrateur** : `admin` / `admin`

Une fois connecté, vous accédez au tableau de bord principal avec plusieurs onglets thématiques.

---

## Pages et Fonctionnalités

### **Graphiques** - Visualisation Interactive des Données

Cette page centralise les **indicateurs clés** et les **graphiques interactifs** pour une analyse approfondie.

#### **Indicateurs Clés (KPI)**
Trois valueBox affichent :
- **Nombre total de logements DPE** : compteur dynamique du nombre d'entrées
- **Surface moyenne des logements** : calculée en m²
- **Pourcentage d'isolation "très bonne"** : indicateur de qualité énergétique

#### **Graphiques Plotly Interactifs**
L'application propose 4 types de visualisations exportables en PNG :

1. **Histogramme de la consommation énergétique** (kWhep/m²/an)
   - Distribution des consommations pour identifier les tendances
   
2. **Diagramme en barres des étiquettes DPE** (A, B, C, D, E, F, G)
   - Répartition visuelle si les habitations possèdent un bilan plustôt positif ou négatif
   
3. **Box plot du coût total des 5 usages** (€)
   - Avec option d'exclusion des valeurs extrêmes pour une meilleure lisibilité
   
4. **Nuage de points personnalisable** (X vs Y)
   - Sélection libre de deux variables numériques
   - Affichage du **coefficient de corrélation** (r)
   - Droite de **régression linéaire** superposée

**Astuce** : Survolez les graphiques pour afficher les détails et utilisez les outils de zoom intégrés.

---

### **Cartographie** - Localisation Géographique des Logements

Carte interactive **Leaflet** affichant tous les logements DPE du département.

**Fonctionnalités** :
- **Clustering automatique** : les marqueurs se regroupent pour faciliter la navigation
- **Popups informatifs** : cliquez sur un marqueur pour voir :
  - Adresse complète
  - Étiquette DPE
  - Consommation énergétique (kWh/m²)
- **Zoom et navigation** : explorez les zones géographiques librement

**Utilité** : Identifier les zones où le plus de DPE on été fait.

---

### **Tableaux** - Export et Exploration des Données Brutes

Cette page permet de **consulter**, **filtrer** et **exporter** les données.

**Fonctionnalités** :
- **Tableau interactif DT** : 
  - Recherche globale et par colonne
  - Tri multi-colonnes
  - Pagination personnalisable (10, 25, 50, 100 lignes)
  
- **Bouton "Rafraîchir les données (API)"** :
  - Récupère automatiquement les **nouveaux DPE** publiés sur l'API ADEME
  - Affiche la date de dernière mise à jour
  - Mise à jour incrémentale (seules les nouvelles données sont ajoutées)
  
- **Bouton "Exporter en CSV"** :
  - Télécharge les données actuellement filtrées
  - Format CSV avec encodage UTF-8
  - Nom du fichier : `dpe_ain_01_filtre_[DATE].csv`

---

### **Filtres** - Personnalisation de l'Analyse

Page dédiée au **filtrage dynamique** des données pour des analyses ciblées.

#### **Filtres Numériques & Dates**
- **Plage de dates** : sélectionnez la période d'établissement des DPE
- **Surface habitable** : slider pour définir la fourchette (en m²)

#### **Filtres Catégoriels** (sélection multiple)
- **Étiquette DPE** : A, B, C, D, E, F, G
- **Type de bâtiment** : maison, appartement, immeuble...
- **Classe d'inertie** : légère, moyenne, lourde, très lourde
- **Type d'énergie N1** : électricité, gaz, fioul...
- **Énergie principale de chauffage**
- **État du logement** : neuf ou existant

**Bouton "Appliquer les filtres"** : actualise instantanément tous les graphiques, tableaux et la carte.

**Conseil** : Combinez plusieurs filtres pour des analyses précises (ex : logements F/G avec chauffage électrique).

---

### **Contexte** - Informations et Documentation

Page informative présentant :
- **Contexte du projet** : enjeux de sobriété énergétique
- **Objectifs de l'application** : 5 objectifs clés
- **Source des données** : liens vers les API ADEME
- **Périmètre de l'analyse** : département, période, nombre de DPE
- **Classification DPE** : explication des étiquettes A à G avec codes couleur
- **Fonctionnalités principales** : résumé des 4 pages opérationnelles
- **Logos** : ENEDIS et ADEME

---

## Personnalisation de l'Interface

### **Sélecteur de Thème**
En haut à droite du tableau de bord, changez le thème visuel parmi **12 options** :
- **Couleurs** : Bleu, Noir, Violet, Vert, Rouge, Jaune
- **Variantes** : versions standards et "Clair" (Light)

Le thème est appliqué instantanément sans recharger l'application.

---

## Export des Résultats

L'application propose **5 boutons d'export** :

1. **Graphiques en PNG** : 4 boutons individuels pour chaque graphique
   - Format haute résolution
   - Taille : 10x6 pouces
   - Nom automatique avec date

2. **Données en CSV** : export des données filtrées
   - Compatible Excel
   - Encodage UTF-8 pour les caractères spéciaux

---

## Mise à Jour des Données

**Fonctionnalité "Rafraîchir les données (API)"** :
- Détecte automatiquement la date du dernier DPE en base
- Interroge l'API ADEME pour récupérer les nouveaux DPE
- Évite les doublons grâce à un système de déduplication
- Affiche un message de confirmation avec le nombre de lignes ajoutées

**Note** : La mise à jour peut prendre quelques minutes selon le volume de nouvelles données.

---

## Conseils d'Utilisation

### **Pour une Analyse Efficace** :
1. Commencez par la page **Contexte** pour comprendre les données
2. Utilisez les **Filtres** pour cibler votre analyse
3. Consultez les **Graphiques** pour des insights visuels
4. Explorez la **Cartographie** pour la dimension spatiale
5. Exportez vos résultats via les **Tableaux**

### **Bonnes Pratiques** :
- Appliquez les filtres progressivement pour observer l'impact
- Utilisez le nuage de points pour explorer les corrélations
- Excluez les valeurs extrêmes sur le box plot pour plus de clarté
- Rafraîchissez régulièrement les données pour rester à jour