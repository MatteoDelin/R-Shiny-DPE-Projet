# Packages de l'application 
library(shiny)
library(leaflet)
library(bslib)
library(ggplot2)
library(DT)
library(dplyr)
library(plotly)
library(sf)
library(shinydashboard)
library(thematic)
library(httr)
library(jsonlite)
library(shinyjs)
library(shinyauthr)
library(sodium)
library(lubridate)

#install.packages(c("shiny","leaflet","ggplot", "DT", "dplyr","ploty","bslib","sf","shinydashboard","thematic","httr","jsonlite","shinyjs","shinyauthr","sodium","lubridate"))


extract_data = function(){
  df = read.csv("https://raw.githubusercontent.com/MatteoDelin/iut_sd2_rshiny_enedis/refs/heads/main/data/dpe_clean.csv") #Lien vers le fichier de données stocké sur GitHub
  
  # Convertie certaine variable dans leur bon type
  df$code_postal_ban = as.character(df$code_postal_ban)
  df$code_insee_ban = as.character(df$code_insee_ban)
  df$code_region_ban = as.character(df$code_region_ban)
  df$code_departement_ban = as.character(df$code_departement_ban)
  
  return(df)
}

filtre_map = function(df){
  
  # Preparation des coordonées pour la carte
  df$latitude = NA_real_
  df$longitude = NA_real_
  valid_coords = !is.na(df$coordonnee_cartographique_x_ban) & 
                  !is.na(df$coordonnee_cartographique_y_ban)
  
  sf_data = st_as_sf(df[valid_coords, ], 
                      coords = c("coordonnee_cartographique_x_ban", 
                                 "coordonnee_cartographique_y_ban"), 
                      crs = 2154,  # Lambert-93
                      remove = FALSE)
  
  sf_data_wgs84 = st_transform(sf_data, crs = 4326)  # WGS84
  
  coords_wgs84 = st_coordinates(sf_data_wgs84)
  
  # Convertie les données géographique de la base en données exploitable par leaflet
  df$latitude[valid_coords] = coords_wgs84[, "Y"]
  df$longitude[valid_coords] = coords_wgs84[, "X"]
  
  # Garde uniquement les coordonées se trouvant dans le département de l'Ain pour éviter d'avoir les points (0,0) des lignes sans coordonée de base
  df = subset(df, (longitude > 4 & latitude > 44))
  
  return(df)
}

# Fonction pour récupérer les nouvelles données via API
refresh_api = function(date_derniere_maj) {
  code_departement = c("01") # Définie la liste des départements à extraire
  
  ls_base_url = c("https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines",
                  "https://data.ademe.fr/data-fair/api/v1/datasets/dpe02neuf/lines")
  
  select_fields = "numero_dpe,date_etablissement_dpe,etiquette_dpe,type_batiment,surface_habitable_logement,classe_inertie_batiment,adresse_ban,code_postal_ban,code_insee_ban,code_region_ban,code_departement_ban,coordonnee_cartographique_x_ban,coordonnee_cartographique_y_ban,deperditions_enveloppe,qualite_isolation_enveloppe,conso_5_usages_ep,conso_5_usages_par_m2_ep,type_energie_n1,cout_total_5_usages,type_energie_principale_chauffage"
  
  type_dpe = c("existant","neuf") #liste des type de DPE pour ajouter une colonne et pouvoir les filtrer plus tard
  i=0
  
  date_fin = Sys.Date()
  
  MAX_SIZE = 10000 # Taille maximale de page
  cpt = 0
  
  # Initialisation du DataFrame principal
  df = data.frame(numero_dpe = character(), date_etablissement_dpe = character(), etiquette_dpe = character(),
                  type_batiment = character(), surface_habitable_logement = numeric(),
                  classe_inertie_batiment = character(), adresse_ban = character(), code_postal_ban = character(),
                  code_insee_ban = character(), code_region_ban = character(), code_departement_ban = character(), coordonnee_cartographique_x_ban = numeric(),
                  coordonnee_cartographique_y_ban = numeric(), deperditions_enveloppe = numeric(),
                  qualite_isolation_enveloppe = character(), conso_5_usages_ep = numeric(),
                  conso_5_usages_par_m2_ep = numeric(), type_energie_n1 = character(),
                  cout_total_5_usages = numeric(), type_energie_principale_chauffage = character(), type_dpe = character(), stringsAsFactors = FALSE)

  # Boucles pour éviter de dépasser les 10000 lignes
  for (base_url in ls_base_url) {
    i=i+1
    for (code_dep in code_departement) {
      date_debut = as.Date(date_derniere_maj)
      while(date_debut<date_fin){
        annee=year(date_debut)
        mois=month(date_debut)
        
        # Preparation des date de debut et de fin de la requête API
        if (mois<10){
          date_debut = paste0(annee,"-0",mois,"-01")
        }
        else{
          date_debut = paste0(annee,"-",mois,"-01")
        }
        
        if (mois==12){
          date_fin_mois = paste0(annee+1,"-01-01")
        }
        else if (mois+1<10){
          date_fin_mois = paste0(annee,"-0",mois+1,"-01")
        }
        else{
          date_fin_mois = paste0(annee,"-",mois+1,"-01")
        }
        
        # Construction du query_string
        query_string = paste0('code_departement_ban:', code_dep,
                              ' AND date_etablissement_dpe:[', date_debut, ' TO ', date_fin_mois, ']')
        
        # Paramètres de la requête (incluant la page actuelle)
        params = list(
          size = MAX_SIZE,
          select = select_fields,
          qs = query_string
        )
        
        # Exécution de la requête
        response = GET(modify_url(base_url, query = params))
        
        # Recuperation du résultat et traitement afin qu'on puisse l'utiliser après
        temp_data = fromJSON(rawToChar(response$content), flatten = FALSE)
        temp_df = temp_data$result
        temp_df$type_dpe = type_dpe[i]
        nb_rows = ifelse(is.null(nrow(temp_df)), 0, nrow(temp_df))
        
        # Ajout des données au DataFrame principal si le dataframe n'est pas vide
        if (!is.null(nrow(temp_df)) && nrow(temp_df) > 0) {
          df = dplyr::bind_rows(df, temp_df)
        }
        
        # Avancer de la date au mois suivant pour la requette suivante
        if (mois==12){
          date_debut=paste0(annee+1,"-01-01")
        }
        else{
          date_debut=paste0(annee,"-",mois+1,"-01")
        }

        Sys.sleep(0.1) # Pause entre les requêtes pour ne pas surcharger le serveur
      }
    }
  }
  df$`_score` = NULL # Retire la colonne _score automatiquement présente dans les résulat car elle n'est pas utile
  return(df)
}

table_data=extract_data() # Stok les données dans un dataframe

# Base d'utilisateurs pour se connecter
user_base = tibble::tibble(
  user = c("admin", "user"),
  password = sapply(c("admin", "Python DASH > R Shiny"), sodium::password_store),
  permissions = c("admin", "C'est juste la vérité"),
  name = c("Administrateur", "Utilisateur")
)

# Création du ui en tant que FluidPage 
ui = fluidPage(
  shinyjs::useShinyjs(),

  tags$head(
    # Liens vers le fichier de style de l'application
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
    
    # Ajout d'une brique de code JS génerer grâce à ChatGPT afin de pouvoir gerer le changement de thème de la page
    tags$script(HTML("
    Shiny.addCustomMessageHandler('change_skin', function(skin) {
      // Enlever toutes les classes skin-*
      $('body').removeClass(function(index, className) {
        return (className.match(/\\bskin-\\S+/g) || []).join(' ');
      });
      // Ajouter la nouvelle classe
      $('body').addClass('skin-' + skin);
    });
    ")),
    
    #Ajout de certaine Class CSS directement dans le code afin qu'elle est le niveau de priorité le plus élever possible
    tags$style(HTML("
    .main-header { height: 50px !important; }
    .main-header .navbar { min-height: 50px !important; }
    .main-header .logo { height: 80px !important; padding: 10px 15px !important; line-height:30px !important}
    .left-side, .main-sidebar {margin-top:30px !important}
  "))
  ),
  
  # Module de login
  shinyauthr::loginUI(
    id = "login",
    title = "Connexion - DPE Ain (01)",
    user_title = "Nom d'utilisateur",
    pass_title = "Mot de passe",
    login_title = "Se connecter"
  ),
  
  # Contenu caché jusqu'à connexion
  shinyjs::hidden(
    div(
      id = "app_content",
      
      dashboardPage(
        skin = "blue",
        
        # Definition du bandeau en haut de la page
        dashboardHeader(
          title = "DPE du département de l'Ain (01)",
          tags$li(
            class = "dropdown",
            tags$label(
              "Thème:", 
            ),
            selectInput(
              inputId = "theme_selector",
              label = NULL,
              choices = c(
                "Bleu" = "blue",
                "Noir" = "black",
                "Violet" = "purple",
                "Vert" = "green",
                "Rouge" = "red",
                "Jaune" = "yellow",
                "Bleu Clair" = "blue-light",
                "Noir Clair" = "black-light",
                "Violet Clair" = "purple-light",
                "Vert Clair" = "green-light",
                "Rouge Clair" = "red-light",
                "Jaune Clair" = "yellow-light"
              ),
              selected = "blue",
            )
          ),
          tags$li(
            class = "dropdown",
            style = "margin-top:25px !important;",
            shinyauthr::logoutUI(id = "logout")
          )
        ),

        # Définition de la sidebar pour pouvoir choisir les pages
        dashboardSidebar(
          sidebarMenu(
            id = "tabs",
            menuItem("Graphiques", tabName = "Graphique", icon = icon("chart-bar")),
            menuItem("Cartographie", tabName = "Cartographie", icon = icon("map-marked-alt")),
            menuItem("Tableaux", tabName = "Tableaux", icon = icon("table")),
            menuItem("Filtres", tabName = "Filtre", icon = icon("filter")),
            menuItem("Contexte", tabName = "Contexte", icon = icon("info-circle"))
          )
        ),
      
        # Définition du coprs de l'application qui changera en fonction de la page choisi
        dashboardBody(tabItems(
          
          # Premier onglet pour les graphique
          tabItem(tabName = "Graphique",
            h3("Analyse et Visualisation des Données DPE"),
            sidebarLayout(
              
              # Colonne de Gauche : Indicateurs
              sidebarPanel(
                width = 3,
                h4("Indicateurs Clés", style = "font-weight: bold; margin-bottom: 20px;"),
                
                fluidRow(
                  valueBoxOutput("vbox_total_dpe", width = 12)
                ),
                tags$hr(),
                
                fluidRow(
                  valueBoxOutput("vbox_surface_moyenne", width = 12)
                ),
                tags$hr(),
                
                fluidRow(
                  valueBoxOutput("vbox_isolation_tres_bonne", width = 12)
                )
              ),
              
            # Colonne de Droite : Graphiques Plotly
            mainPanel(
              width = 9,
              h4("Graphiques Interactifs"),
              
              fluidRow(
                column(12, align = "right",
                       downloadButton("download_histo", "Exporter en PNG", 
                                      icon = icon("download"), class = "btn-sm btn-info")
                )
              ),
              # Affichage de l'histogramme de consomation
              plotlyOutput("plot_histogramme_conso"),
              tags$br(),
              fluidRow(
                column(12, align = "right",
                       downloadButton("download_barres", "Exporter en PNG", 
                                      icon = icon("download"), class = "btn-sm btn-info")
                )
              ),
              # Affichage du bar plot de étiquette DPE
              plotlyOutput("plot_barres_etiquette"),
              tags$br(),
              fluidRow(
                column(12, align = "right",
                       downloadButton("download_boxplot", "Exporter en PNG", 
                                      icon = icon("download"), class = "btn-sm btn-info")
                )
              ),
              checkboxInput("filter_outliers_cout", "Exclure les valeurs extrêmes", value = TRUE),
              # Affichage du box plot du cout 
              plotlyOutput("plot_boxplot_cout"),
              tags$br(),
              # Choix des variables pour le nuage de points
              fluidRow(
                column(6,
                       selectInput("scatter_x", "Axe X (Nuage de points) :", "")
                ),
                column(6,
                       selectInput("scatter_y", "Axe Y (Nuage de points) :", "")
                )
              ),
              tags$h5(textOutput("coeff_cor_text"), style = "font-weight: bold; color: #FF6347; text-align: center;"),
              tags$br(),
              fluidRow(
                column(12, align = "right",
                       downloadButton("download_scatter", "Exporter en PNG", 
                                      icon = icon("download"), class = "btn-sm btn-info")
                )
              ),
              # Affichage du nuage de point pour la coréalation
              plotlyOutput("plot_nuage_points")
              )
            )
          ),
          
          # Deuxième onglet pour la cartographie des DPE
          tabItem(tabName = "Cartographie", 
            leafletOutput("ma_carte", height = "600px")
          ),
          
          # Troisième onglet pour le tableau de toutes les valeurs
          tabItem(tabName = "Tableaux", 
            h3("Tableaux des données"),
            fluidRow(
              column(6,
                     actionButton("refresh_data_api", 
                                  "Rafraîchir les données (API)",
                                  icon = icon("sync-alt"),
                                  class = "btn-warning")
              ),
              column(6, align = "right",
                     downloadButton("download_data", "Exporter en CSV", 
                                    icon = icon("download"),
                                    class = "btn-success")
              )
            ),
            tags$br(),
            uiOutput("message_refresh_api"),
            tags$br(),
            DT::DTOutput("data_table")
          ),
          
          # Quatrième onglet pour la gestion des filtres de données
          tabItem(tabName = "Filtre",
            h3("Filtrer les données de l'application"),
            fluidRow(
              column(12, align = "right",
                     actionButton("appliquer_filtres", "Appliquer les filtres", icon = icon("filter"))
              )
            ),
            fluidRow(
              # Colonne de Gauche (Filtres Numériques & Dates)
              column(6,
                     h4("Filtres Numériques & Dates"),
                     # 1. DATE (Dynamique)
                     uiOutput("date_dpe_ui"),
                     # 2. Surface (Dynamique)
                     uiOutput("surface_habitable_ui")
              ),
              
              # Colonne de Droite (Filtres Catégoriels)
              column(6,
                     h4("Filtres Catégoriels"),
                     uiOutput("etiquette_dpe_ui"),
                     uiOutput("type_batiment_ui"),
                     uiOutput("classe_inertie_ui"),
                     uiOutput("type_energie_n1_ui"),
                     uiOutput("type_chaffage_ui"),
                     uiOutput("type_dpe_ui")
              )
            )
          ),
          
          # Cinquième onglet pour donner le contexte de l'application
          tabItem(tabName = "Contexte",
            fluidRow(
              # SECTION 1 : Présentation du projet
              box(
                width = 12,
                solidHeader = TRUE,
                status = "info",
                title = tags$div(icon("info-circle"), "À propos du projet"),
                fluidRow(
                  column(8,
                         h4("Contexte : Sobriété Énergétique et DPE"),
                         p("Avec l'accélération du changement climatique et la hausse des prix de l'énergie, 
                         la sobriété énergétique est au cœur des préoccupations des Français."),
                         p("Cette application analyse les Diagnostics de Performance Énergétique (DPE) 
                         du département de l'Ain (01) pour comprendre l'impact des différentes 
                         classes énergétiques sur les consommations électriques des logements."),
                         tags$hr(),
                         h4("Objectifs de l'application"),
                         tags$ul(
                           tags$li("Visualiser la répartition des étiquettes DPE dans le département"),
                           tags$li("Identifier les passoires énergétiques (étiquettes F et G)"),
                           tags$li("Analyser les facteurs influençant la performance énergétique"),
                           tags$li("Cartographier les logements selon leur performance énergétique"),
                           tags$li("Fournir des données exploitables pour la transition énergétique")
                         )
                  ),
                  column(4,
                         tags$img(src = "Logo-ENEDIS.png",
                                  width = "100%",
                                  style = "margin-top: 20px;"),
                         tags$br(), tags$br(),
                         tags$img(src = "Logo-ADEME.png",
                                  width = "80%",
                                  style = "margin-top: 20px;")
                  )
                )
              )
            ),
            
            fluidRow(
              # SECTION 2 : Source des données
              box(
                width = 6,
                solidHeader = TRUE,
                status = "primary",
                title = tags$div(icon("database"), "Source des Données"),
                h5("Données ADEME - DPE France"),
                p("Les données proviennent de l'Agence de l'Environnement et de la Maîtrise de l'Énergie (ADEME)."),
                tags$ul(
                  tags$li(tags$b("Logements existants :"), 
                          tags$a(href = "https://data.ademe.fr/datasets/dpe03existant/api-doc",
                                 target = "_blank", "DPE v2 - Logements existants")),
                  tags$li(tags$b("Logements neufs :"), 
                          tags$a(href = "https://data.ademe.fr/datasets/dpe02neuf/api-doc",
                                 target = "_blank", "DPE v2 - Logements neufs"))
                ),
                tags$hr(),
                h5("Périmètre de l'analyse"),
                tags$ul(
                  tags$li(tags$b("Département :"), "Ain (01)"),
                  tags$li(tags$b("Période :"), textOutput("periode_data", inline = TRUE)),
                  tags$li(tags$b("Nombre de DPE :"), textOutput("nombre_total_dpe", inline = TRUE))
                )
              ),
              
              # SECTION 3 : Comprendre les étiquettes DPE
              box(
                width = 6,
                solidHeader = TRUE,
                status = "warning",
                title = tags$div(icon("certificate"), "Comprendre les Étiquettes DPE"),
                h5("Classification énergétique"),
                p("Le DPE classe les logements selon leur consommation énergétique annuelle :"),
                tags$div(
                  style = "margin: 10px 0;",
                  tags$span(style = "background-color: #008000; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 5px;", "A"),
                  "≤ 70 kWh/m²/an - Très performant"
                ),
                tags$div(
                  style = "margin: 10px 0;",
                  tags$span(style = "background-color: #50A000; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 5px;", "B"),
                  "71 à 110 kWh/m²/an - Performant"
                ),
                tags$div(
                  style = "margin: 10px 0;",
                  tags$span(style = "background-color: #A0D000; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 5px;", "C"),
                  "111 à 180 kWh/m²/an - Assez performant"
                ),
                tags$div(
                  style = "margin: 10px 0;",
                  tags$span(style = "background-color: #FFFF00; color: black; padding: 5px 10px; border-radius: 3px; margin-right: 5px;", "D"),
                  "181 à 250 kWh/m²/an - Peu performant"
                ),
                tags$div(
                  style = "margin: 10px 0;",
                  tags$span(style = "background-color: #FFC000; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 5px;", "E"),
                  "251 à 330 kWh/m²/an - Énergivore"
                ),
                tags$div(
                  style = "margin: 10px 0;",
                  tags$span(style = "background-color: #FF8000; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 5px;", "F"),
                  "331 à 420 kWh/m²/an - Très énergivore"
                ),
                tags$div(
                  style = "margin: 10px 0;",
                  tags$span(style = "background-color: #FF0000; color: white; padding: 5px 10px; border-radius: 3px; margin-right: 5px;", "G"),
                  "> 420 kWh/m²/an - Passoire énergétique"
                )
              )
            ),
        
            fluidRow(
              # SECTION 4 : Fonctionnalités de l'application
              box(
                width = 12,
                solidHeader = TRUE,
                status = "primary",
                title = tags$div(icon("star"), "Fonctionnalités de l'Application"),
                fluidRow(
                  column(3,
                         h5(icon("chart-bar"), "Graphiques"),
                         p("Visualisations interactives des données DPE")
                  ),
                  column(3,
                         h5(icon("map-marked-alt"), "Cartographie"),
                         p("Carte interactive des logements avec clustering")
                  ),
                  column(3,
                         h5(icon("table"), "Tableaux"),
                         p("Export CSV et filtres avancés sur les données")
                  ),
                  column(3,
                         h5(icon("filter"), "Filtres"),
                         p("Filtrage multi-critères pour analyses personnalisées")
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

server = function(input, output, session) {
  
  # Définir l'authentification
  credentials <- shinyauthr::loginServer(
    id = "login",
    data = user_base,
    user_col = user,
    pwd_col = password,
    sodium_hashed = TRUE,
    log_out = reactive(logout_init())
  )
  
  # Définir le logout de l'application
  logout_init <- shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )
  
  # Gerer l'affichage pour la première connexion
  observe({
    if (credentials()$user_auth) {
      shinyjs::show(id = "app_content")
      shinyjs::hide(id = "login")
      updateTabItems(session, "tabs", selected = "Graphique")
    } else {
      shinyjs::hide(id = "app_content")
      shinyjs::show(id = "login")
    }
  })
  
  # Gestion du changement de thème
  observeEvent(input$theme_selector, {

    # Envoyer le message JavaScript pour changer le thème
    session$sendCustomMessage(type = "change_skin", message = input$theme_selector)
    
    # Définition des thèmes possible pour l'application
    theme_names <- c(
      "blue" = "Bleu",
      "black" = "Noir",
      "purple" = "Violet",
      "green" = "Vert",
      "red" = "Rouge",
      "yellow" = "Jaune",
      "blue-light" = "Bleu Clair",
      "black-light" = "Noir Clair",
      "purple-light" = "Violet Clair",
      "green-light" = "Vert Clair",
      "red-light" = "Rouge Clair",
      "yellow-light" = "Jaune Clair"
    )
    
    # Notification pour prévenir du changement de thème
    showNotification(
      paste("Thème changé:", theme_names[input$theme_selector]),
      type = "message",
      duration = 2
    )
  }, ignoreInit = TRUE)
  
  # Initialiser les données réactives baser sur le csv 
  rv = reactiveValues(data = table_data)
  

  # Rendu de la carte apprès application du filtre des coordonnées
  output$ma_carte = renderLeaflet({
    leaflet(filtre_map(rv$data)) %>%
      addTiles() %>%
      addMarkers(lng = ~longitude,
                 lat = ~latitude,
                 clusterOptions = markerClusterOptions(),
                 popup = ~paste0(
                   "<b>Adresse:</b> ", adresse_ban,
                   "<br><b>Étiquette:</b> ", etiquette_dpe,
                   "<br><b>Conso:</b> ", round(conso_5_usages_par_m2_ep, 1), " kWh/m²"
                 ))
  })
  
  
  # Rendu du tableau de données
  output$data_table = renderDT({
    datatable(
      rv$data, 
      options = list(
        scrollX = TRUE,           # Scroll horizontal
        scrollCollapse = TRUE,
        pageLength = 25,          # 25 lignes par page
        lengthMenu = c(10, 25, 50, 100),  # Options de pagination
        dom = 'Blfrtip',
        searchHighlight = TRUE,   # Surligner les recherches
        language = list(
          search = "Rechercher :",
          lengthMenu = "Afficher _MENU_ lignes",
          info = "Affichage de _START_ à _END_ sur _TOTAL_ entrées",
          paginate = list(
            first = "Premier",
            last = "Dernier",
            `next` = "Suivant",
            previous = "Précédent"
          )
        )
      ),
      filter = 'top',  # Filtres en haut de chaque colonne
      rownames = FALSE,  # Pas de numéros de lignes
      class = 'cell-border stripe hover'  # Style du tableau
    )
  })
  
  # Téléchargement des données en CSV
  output$download_data = downloadHandler(
    filename = function() {
      paste("dpe_ain_01_filtre_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      # Récupérer les lignes visibles après filtrage DT
      data_to_export = rv$data

      if (!is.null(input$data_table_rows_all)) {
        data_to_export = rv$data[input$data_table_rows_all, ]
      }
      
      write.csv(data_to_export, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
  
  ###### Page de Filtre ######
  
  # Filtre des Date
  output$date_dpe_ui = renderUI({
    
    dates = as.Date(table_data$date_etablissement_dpe) # Récupère toutes les date de DPE en les convertissante en format Date
    
    dateRangeInput(
      "filtre_date_dpe",
      label = "Date d'établissement DPE :",
      # Utilisation de na.rm = TRUE pour ignorer les NA
      start = min(dates, na.rm = TRUE), #pemier DPE de la base
      end = max(dates, na.rm = TRUE) #dernier DPE de la base 
    )
  })
  
  # Filtre des surface Surface
  output$surface_habitable_ui = renderUI({
    
    surfaces = table_data$surface_habitable_logement #Ensemble des surfaces des DPE
    
    min_surface = floor(min(surfaces, na.rm = TRUE)) #plus petit surface
    max_surface = ceiling(max(surfaces, na.rm = TRUE)) #plus grande surface
    
    sliderInput(
      "filtre_surface_habitable",
      label = "Surface habitable du logement :",
      min = min_surface,
      max = max_surface,
      value = c(min_surface, max_surface),
      step = 1
    )
  })
  
  # Filtre etiquette DPE
  output$etiquette_dpe_ui = renderUI({
    selectInput(
      "filtre_etiquette_dpe",
      label = "Étiquette DPE :",
      # trie les choix pour une meilleure lisibilité
      choices = sort(unique(table_data$etiquette_dpe)), # Récupère une seul fois toutes les étiquettes de DPE
      multiple = TRUE
    )
  })
  
  # Filtre type batiment
  output$type_batiment_ui = renderUI({
    selectInput(
      "filtre_type_batiment",
      label = "Type de bâtiment :",
      choices = sort(unique(table_data$type_batiment)), # Récupère une seul fois toutes les type de batiement parmis les DPE
      multiple = TRUE
    )
  })
  
  # Filtre classe inertie
  output$classe_inertie_ui = renderUI({
    selectInput(
      "filtre_classe_inertie",
      label = "Classe d'inertie du bâtiment :",
      choices = sort(unique(table_data$classe_inertie_batiment)), # Récupère une seul fois toutes les classe innertie de DPE
      multiple = TRUE
    )
  })
  
  # Filtre type energie n1
  output$type_energie_n1_ui = renderUI({
    selectInput(
      "filtre_type_energie_n1",
      label = "Type d'énergie N1 :",
      choices = sort(unique(table_data$type_energie_n1)), # Récupère une seul fois toutes les type d'énergie n1 de DPE
      multiple = TRUE
    )
  })
  
  # Filtre energie chaffage
  output$type_chaffage_ui = renderUI({
    selectInput(
      "filtre_type_chaffage",
      label = "Énergie principale de chauffage :",
      choices = sort(unique(table_data$type_energie_principale_chauffage)), # Récupère une seul fois toutes les type de chaffage de DPE
      multiple = TRUE
    )
  })
  
  # Filtre Etat logement
  output$type_dpe_ui = renderUI({
    selectInput(
      "filtre_type_dpe",
      label = "Etat du logement :",
      choices = sort(unique(table_data$type_dpe)), # Récupère une seul fois toutes les type de logement de DPE (neuf ou existant)
      multiple = TRUE
    )
  })
  
  # Applique le filtre en fonction des ce qui à été choisis
  observeEvent(input$appliquer_filtres, {
    
    data = table_data # Récupère les données vierge de modification pour le filtre
    # 1. FILTRAGE DATE
    if (!is.null(input$filtre_date_dpe) && length(input$filtre_date_dpe) == 2) {
      data = data %>%
        filter(as.Date(date_etablissement_dpe) >= input$filtre_date_dpe[1] &
                 as.Date(date_etablissement_dpe) <= input$filtre_date_dpe[2])
    }
    
    # 2. FILTRAGE SURFACE
    if (!is.null(input$filtre_surface_habitable) && length(input$filtre_surface_habitable) == 2) {
      data = data %>%
        filter(surface_habitable_logement >= input$filtre_surface_habitable[1] &
                 surface_habitable_logement <= input$filtre_surface_habitable[2])
    }
    
    # 3. FILTRAGES CATÉGORIELS
    if (!is.null(input$filtre_etiquette_dpe)) {
      data = data %>% filter(etiquette_dpe %in% input$filtre_etiquette_dpe)
    }
    if (!is.null(input$filtre_type_batiment)) {
      data = data %>% filter(type_batiment %in% input$filtre_type_batiment)
    }
    if (!is.null(input$filtre_classe_inertie)) {
      data = data %>% filter(classe_inertie_batiment %in% input$filtre_classe_inertie)
    }
    if (!is.null(input$filtre_code_departement)) {
      data = data %>% filter(code_departement_ban %in% input$filtre_code_departement)
    }
    if (!is.null(input$filtre_type_energie_n1)) {
      data = data %>% filter(type_energie_n1 %in% input$filtre_type_energie_n1)
    }
    if (!is.null(input$filtre_type_chaffage)) {
      data = data %>% filter(type_energie_principale_chauffage %in% input$filtre_type_chaffage)
    }
    if (!is.null(input$filtre_type_dpe)) {
      data = data %>% filter(type_dpe %in% input$filtre_type_dpe)
    }
    
    rv$data = data
  })
  
  
# ----------------------------------------------------
# Rendu des KPI
# ----------------------------------------------------
  
  # KPI 1 : Total DPE
  output$vbox_total_dpe = renderValueBox({
    data_kpi = rv$data

    total = format(nrow(data_kpi), big.mark = " ") #Compte le nombre de ligne dans la table et le convertie en string
    
    valueBox(
      value = total,
      subtitle = "Logements DPE",
      icon = icon("home", style ="font-size: 50px;"),
      color = "blue"
    )
  })
  
  # KPI 2 : Surface moyenne
  output$vbox_surface_moyenne = renderValueBox({
    data_kpi = rv$data

    surface_moy = round(mean(data_kpi$surface_habitable_logement, na.rm = TRUE), 0) #Calcul la surface moyenne des DPE
    
    valueBox(
      value = paste(surface_moy, "m²"),
      subtitle = "Surface moyenne",
      icon = icon("ruler-combined", style ="font-size: 50px;"),
      color = "yellow"
    )
  })
  
  # KPI 3 : Isolation très bonne
  output$vbox_isolation_tres_bonne = renderValueBox({
    data_kpi = rv$data

    nb_tres_bonne = nrow(subset(data_kpi, qualite_isolation_enveloppe == "très bonne")) # Calcul le nombre de DPE avec la qualite d'isolation très bonne
    
    pourcentage = if(nrow(data_kpi) > 0) {
      round((nb_tres_bonne / nrow(data_kpi)) * 100, 1)  # Ramène se nombre à un pourcentage du total de DPE
    } else { 0 }
    
    valueBox(
      value = paste0(pourcentage, "%"),
      subtitle = "Isolation très bonne",
      icon = icon("shield-alt", style ="font-size: 50px;"),
      color = "green"
    )
  })
  
  # ----------------------------------------------------
  # Rendu des Graphiques
  # ----------------------------------------------------
  
  # Graphique 1 : Histogramme de conso_5_usages_par_m2_ep
  output$plot_histogramme_conso = renderPlotly({
    data_filtered = rv$data
    p = ggplot(data_filtered, aes(x = conso_5_usages_par_m2_ep)) +
      geom_histogram(bins = 30, fill = "#17a2b8", color = "white") +
      labs(title = "Distribution de la Consommation Énergétique (EP/m²)",
           x = "Consommation (kWhep/m²/an)",
           y = "Fréquence") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Graphique 2 : Barres des étiquette_dpe
  output$plot_barres_etiquette = renderPlotly({
    data_filtered = rv$data
    
    # Compte les occurrences
    data_count = count(data_filtered, etiquette_dpe)
    
    # Converti en facteur avec les niveaux ordonnés
    data_count$etiquette_dpe = factor(data_count$etiquette_dpe, 
                                      levels = sort(unique(data_filtered$etiquette_dpe)))
    
    # Créer le graphique
    p = ggplot(data_count, aes(x = etiquette_dpe, y = n, fill = etiquette_dpe)) +
      geom_bar(stat = "identity") +
      labs(title = "Répartition par Étiquette DPE",
           x = "Étiquette DPE",
           y = "Nombre de DPE") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Graphique 3 : Box plot du cout_total_5_usages
  output$plot_boxplot_cout = renderPlotly({
    data_filtered = rv$data
    
    # Regarde si il faut filtrer les extrèmes
    if(input$filter_outliers_cout) {
      # Filtrer les extrêmes
      Q1 = quantile(data_filtered$cout_total_5_usages, 0.25, na.rm = TRUE)
      Q3 = quantile(data_filtered$cout_total_5_usages, 0.75, na.rm = TRUE)
      IQR = Q3 - Q1
      
      data_filtered = data_filtered[data_filtered$cout_total_5_usages >= (Q1 - 1.5 * IQR) & 
                                      data_filtered$cout_total_5_usages <= (Q3 + 1.5 * IQR), ]
    }
    
    p = ggplot(data_filtered, aes(y = cout_total_5_usages)) +
      geom_boxplot(fill = "#ffc107", color = "#d39e00") +
      labs(title = "Distribution du Coût Total des 5 Usages",
           y = "Coût Total (€)") +
      theme_minimal()
    
    plotly_obj = ggplotly(p)
    plotly_obj = layout(plotly_obj, showlegend = FALSE)
    
    plotly_obj
  })
  
  # Graphique 4 : Nuage de points

  # Identifier les colonnes numériques pour le nuage de points
  numeric_cols = reactive({
    data = rv$data
    # Exclure les coordonnées géographiques
    cols = names(data)[sapply(data, is.numeric)]
    cols = cols[!cols %in% c("coordonnee_cartographique_x_ban",
                             "coordonnee_cartographique_y_ban",
                             "code_postal_ban",
                             "code_departement_ban",
                             "code_region_ban",
                             "adresse_ban",
                             "code_insee_ban")]
    return(cols)
  })
  
  # Mettre à jour les choix du selectInput pour l'axe X
  observe({
    cols = numeric_cols()
    
    updateSelectInput(session,
                      "scatter_x", 
                      choices = cols,
                      selected = "")
  })
  
  # Mettre à jour les choix du selectInput pour l'axe Y
  observe({
    cols = numeric_cols()
    
    updateSelectInput(session,
                      "scatter_y", 
                      choices = cols,
                      selected = "")
  })
    
  # Graphique 4 : Nuage de points avec corrélation et régression
  # Affichage du coefficient de corrélation
  output$coeff_cor_text = renderText({
    
    if(is.null(input$scatter_x) || is.null(input$scatter_y) ||
       input$scatter_x == "" || input$scatter_y == "") {
      return("")
    }
    
    data_filtered = rv$data

    data_clean = data_filtered[is.finite(data_filtered[[input$scatter_x]]) & 
                               is.finite(data_filtered[[input$scatter_y]]), ]
    
    if(nrow(data_clean) < 2) {
      return("Corrélation : Non calculable")
    }
    
    correlation = cor(data_clean[[input$scatter_x]], 
                       data_clean[[input$scatter_y]], 
                       use = "complete.obs")
    
    paste("Coefficient de corrélation (r) :", round(correlation, 3))
  })
  
  # Graphique nuage de points
  output$plot_nuage_points = renderPlotly({
    
    if(is.null(input$scatter_x) || is.null(input$scatter_y) || input$scatter_x == "" || input$scatter_y == "") {
      empty_plot = plotly_empty()
      empty_plot = layout(
                          empty_plot,
                          title = list(text = "Veuillez sélectionner les variables X et Y",
                                       font = list(size = 16, color = "#777")),
                          xaxis = list(showgrid = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, showticklabels = FALSE)
                        )
      
      return(empty_plot)
    }
    
    data_clean = rv$data
    
    if(nrow(data_clean) == 0) {
      empty_plot = plotly_empty()
      empty_plot = layout(empty_plot, title = "Aucune donnée valide")
      return(empty_plot)
    }
    
    p = ggplot(data_clean, aes(x = !!sym(input$scatter_x), 
                               y = !!sym(input$scatter_y))) +
      geom_point(alpha = 0.5, size = 2, color = "#20c997") +
      geom_smooth(method = "lm", se = FALSE,  # se = FALSE pour enlever l'intervalle
                  color = "#FF6347", 
                  formula = y ~ x, 
                  linewidth = 1) +
      labs(title = paste("Relation entre", input$scatter_x, "et", input$scatter_y),
           x = input$scatter_x,
           y = input$scatter_y) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
    
    plotly_obj = ggplotly(p)
    plotly_obj = layout(plotly_obj, showlegend = FALSE)
    plotly_obj
  })
  
  ### Fonction d'export des graphiques
  # Export graphique Histogramme
  output$download_histo = downloadHandler(
    filename = function() {
      paste("histogramme_conso_", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      data_filtered = rv$data
      p = ggplot(data_filtered, aes(x = conso_5_usages_par_m2_ep)) +
        geom_histogram(bins = 30, fill = "#17a2b8", color = "white") +
        labs(title = "Distribution de la Consommation Énergétique (EP/m²)",
             x = "Consommation (kWhep/m²/an)",
             y = "Fréquence") +
        theme_minimal()
      ggsave(file, plot = p, width = 10, height = 6, dpi = 300)
    }
  )
  
  # Export graphique Barres
  output$download_barres = downloadHandler(
    filename = function() {
      paste("repartition_etiquettes_", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      data_filtered = rv$data
      p = data_filtered %>%
        count(etiquette_dpe) %>%
        mutate(etiquette_dpe = factor(etiquette_dpe, levels = c("A", "B", "C", "D", "E", "F", "G", "Vierge"))) %>%
        ggplot(aes(x = etiquette_dpe, y = n, fill = etiquette_dpe)) +
        geom_bar(stat = "identity") +
        labs(title = "Répartition par Étiquette DPE",
             x = "Étiquette DPE",
             y = "Nombre de DPE") +
        theme_minimal()
      ggsave(file, plot = p, width = 10, height = 6, dpi = 300)
    }
  )
  
  # Export graphique Boxplot
  output$download_boxplot = downloadHandler(
    filename = function() {
      paste("boxplot_cout_", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      data_filtered = rv$data
      
      if(input$filter_outliers_cout) {
        Q1 = quantile(data_filtered$cout_total_5_usages, 0.25, na.rm = TRUE)
        Q3 = quantile(data_filtered$cout_total_5_usages, 0.75, na.rm = TRUE)
        IQR = Q3 - Q1
        data_filtered = data_filtered %>%
          filter(cout_total_5_usages >= (Q1 - 1.5 * IQR) & 
                   cout_total_5_usages <= (Q3 + 1.5 * IQR))
      }
      
      p = ggplot(data_filtered, aes(y = cout_total_5_usages)) +
        geom_boxplot(fill = "#ffc107", color = "#d39e00") +
        labs(title = "Distribution du Coût Total des 5 Usages",
             y = "Coût Total (€)") +
        theme_minimal()
      ggsave(file, plot = p, width = 10, height = 6, dpi = 300)
    }
  )
  
  # Export graphique Nuage de points
  output$download_scatter = downloadHandler(
    filename = function() {
      paste("nuage_points_", input$scatter_x, "_", input$scatter_y, "_", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      
      data_filtered = rv$data
      data_clean = data_filtered %>%
        filter(is.finite(!!sym(input$scatter_x)) & 
                 is.finite(!!sym(input$scatter_y)))
      
      p = ggplot(data_clean, aes(x = !!sym(input$scatter_x), 
                                 y = !!sym(input$scatter_y))) +
        geom_point(alpha = 0.5, size = 2, color = "#20c997") +
        geom_smooth(method = "lm", se = FALSE, color = "#FF6347", 
                    formula = y ~ x, linewidth = 1) +
        labs(title = paste("Relation entre", input$scatter_x, "et", input$scatter_y),
             x = input$scatter_x,
             y = input$scatter_y) +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5, face = "bold"))
      
      ggsave(file, plot = p, width = 10, height = 6, dpi = 300)
    }
  )
  
  ### Page Contexte
  # Période des données
  output$periode_data = renderText({
    dates = as.Date(rv$data$date_etablissement_dpe)
    min_date = min(dates, na.rm = TRUE)
    max_date = max(dates, na.rm = TRUE)
    paste(format(min_date, "%d/%m/%Y"), "au", format(max_date, "%d/%m/%Y"))
  })
  
  # Nombre total de DPE
  output$nombre_total_dpe = renderText({
    format(nrow(table_data), big.mark = " ")
  })
  
  ### Gestion du rephresh de l'API
  observeEvent(input$refresh_data_api, {
    
    showNotification(
      "Récupération des nouvelles données via l'API ADEME en cours...",
      type = "message",
      duration = NULL,
      id = "refresh_notif"
    )
    
    shinyjs::disable("refresh_data_api")
    
    date_derniere <- max(as.Date(table_data$date_etablissement_dpe), na.rm = TRUE)
    
    result <- refresh_api(date_derniere)
    removeNotification(id = "refresh_notif")
    table_data = unique(dplyr::bind_rows(table_data, result))
    rv$data <- table_data
    
    showNotification(
      paste0(result$nb_lignes, " nouvelles données ajoutées !"),
      type = "message",
      duration = 5
    )
    
    shinyjs::enable("refresh_data_api")
  })
  
  output$message_refresh_api <- renderUI({
    date_derniere <- max(as.Date(table_data$date_etablissement_dpe), na.rm = TRUE)
    
    tags$div(
      class = "alert alert-info",
      role = "alert",
      icon("info-circle"),
      paste(" Dernière donnée dans la base :", format(date_derniere, "%d/%m/%Y"),
            "| Cliquez sur 'Rafraîchir' pour récupérer les nouveaux DPE via l'API ADEME")
    )
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

