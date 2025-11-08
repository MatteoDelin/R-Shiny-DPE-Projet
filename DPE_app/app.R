library(shiny)
library(leaflet)
library(bslib)
library(ggplot2)
library(DT)
library(dplyr)
library(plotly)
library(sf)
library(shinydashboard)

#install.packages(c("shiny","leaflet","ggplot", "DT", "dplyr","ploty","bslib","sf","shinydashboard"))


extract_data = function(){
  df = read.csv("BaseDeDonnes01.csv")
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
  df$latitude[valid_coords] = coords_wgs84[, "Y"]
  df$longitude[valid_coords] = coords_wgs84[, "X"]
  
  df = df %>%
    filter(longitude > 4 & latitude > 44)
  
  return(df)
}

table_data=extract_data()

ui = navbarPage(
  title = "DPE du département de l'Ain (01)",

  # Premier onglet
  tabPanel(
    "Graphique",
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
      h4("Graphiques Interactifs Plotly"),
      # Affichage des graphiques
      plotlyOutput("plot_histogramme_conso"),
      tags$br(),
      plotlyOutput("plot_barres_etiquette"),
      tags$br(),
      checkboxInput("filter_outliers_cout", "Exclure les valeurs extrêmes", value = TRUE),
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
      plotlyOutput("plot_nuage_points")
      )
    )
  ),
  
  # Deuxième onglet
  tabPanel(
    "Cartographie", 
    leafletOutput("ma_carte", height = "600px")
  ),
  
  # Troisième onglet
  tabPanel(
    "Tableaux", 
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
  
  # Quatrième onglet
  tabPanel(
    "Filtre",
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
             uiOutput("type_chaffage_ui")
      )
    )
  ),
  
  # Cinquième onglet
  tabPanel(
    "Contexte",
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
                 tags$img(src = "https://www.soignolles14.fr/wp-content/uploads/2019/03/Logo-ENEDIS.png",
                          width = "100%",
                          style = "margin-top: 20px;"),
                 tags$br(), tags$br(),
                 tags$img(src = "https://upload.wikimedia.org/wikipedia/fr/thumb/0/0d/Logo_ADEME_2020.svg/1200px-Logo_ADEME_2020.svg.png",
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
        ),
        tags$hr(),
        tags$div(
          class = "alert alert-danger",
          role = "alert",
          tags$b(icon("fire"), " Les passoires énergétiques (F et G)"),
          "représentent un enjeu majeur de la transition énergétique."
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
                 p("Visualisations interactives des données DPE avec Plotly")
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

server = function(input, output, session) {
  
  rv = reactiveValues(data = table_data)
  
  # Rendu de la carte
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
        dom = 'Blfrtip',          # B=boutons, l=length, f=filter, r=processing, t=table, i=info, p=pagination
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
      
      # Si vous voulez vraiment les données filtrées par DT aussi,
      # il faut utiliser input$data_table_rows_all pour toutes les lignes
      # ou input$data_table_rows_current pour la page actuelle
      if (!is.null(input$data_table_rows_all)) {
        data_to_export = rv$data[input$data_table_rows_all, ]
      }
      
      write.csv(data_to_export, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
  
  ###### Page de Filtre ###### 
  output$date_dpe_ui = renderUI({
    
    dates = as.Date(table_data$date_etablissement_dpe)
    
    dateRangeInput(
      "filtre_date_dpe",
      label = "Date d'établissement DPE :",
      # Utilisation de na.rm = TRUE pour ignorer les NA
      start = min(dates, na.rm = TRUE),
      end = max(dates, na.rm = TRUE)
    )
  })
  
  # Surface
  output$surface_habitable_ui = renderUI({
    
    surfaces = table_data$surface_habitable_logement
    
    min_surface = floor(min(surfaces, na.rm = TRUE))
    max_surface = ceiling(max(surfaces, na.rm = TRUE))
    
    sliderInput(
      "filtre_surface_habitable",
      label = "Surface habitable du logement :",
      min = min_surface,
      max = max_surface,
      value = c(min_surface, max_surface),
      step = 1
    )
  })
  
  # etiquette DPE
  output$etiquette_dpe_ui = renderUI({
    selectInput(
      "filtre_etiquette_dpe",
      label = "Étiquette DPE :",
      # trier (sort) les choix pour une meilleure lisibilité
      choices = sort(unique(table_data$etiquette_dpe)),
      multiple = TRUE
    )
  })
  
  # type batiment
  output$type_batiment_ui = renderUI({
    selectInput(
      "filtre_type_batiment",
      label = "Type de bâtiment :",
      choices = sort(unique(table_data$type_batiment)),
      multiple = TRUE
    )
  })
  
  # classe inertie
  output$classe_inertie_ui = renderUI({
    selectInput(
      "filtre_classe_inertie",
      label = "Classe d'inertie du bâtiment :",
      choices = sort(unique(table_data$classe_inertie_batiment)),
      multiple = TRUE
    )
  })
  
  # type energie n1
  output$type_energie_n1_ui = renderUI({
    selectInput(
      "filtre_type_energie_n1",
      label = "Type d'énergie N1 :",
      choices = sort(unique(table_data$type_energie_n1)),
      multiple = TRUE
    )
  })
  
  # energie chaffage
  output$type_chaffage_ui = renderUI({
    selectInput(
      "filtre_type_chaffage",
      label = "Énergie principale de chauffage :",
      choices = sort(unique(table_data$type_energie_principale_chauffage)),
      multiple = TRUE
    )
  })
  
  observeEvent(input$appliquer_filtres, {
    
    data = table_data
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
    
    rv$data = data
  })
  
  
# ----------------------------------------------------
# Rendu des KPI
# ----------------------------------------------------
  
  # KPI 1 : Total DPE
  output$vbox_total_dpe = renderValueBox({
    data_kpi = rv$data  # CORRECTION : enlever les ()
    req(data_kpi)
    
    total = format(nrow(data_kpi), big.mark = " ")
    
    valueBox(
      value = total,
      subtitle = "Logements DPE",
      icon = icon("home"),
      color = "blue"
    )
  })
  
  # KPI 2 : Surface moyenne
  output$vbox_surface_moyenne = renderValueBox({
    data_kpi = rv$data  # CORRECTION : enlever les ()
    req(data_kpi, "surface_habitable_logement" %in% names(data_kpi))
    
    surface_moy = round(mean(data_kpi$surface_habitable_logement, na.rm = TRUE), 0)
    
    valueBox(
      value = paste(surface_moy, "m²"),
      subtitle = "Surface moyenne",
      icon = icon("ruler-combined"),
      color = "yellow"
    )
  })
  
  # KPI 3 : Isolation très bonne
  output$vbox_isolation_tres_bonne = renderValueBox({
    data_kpi = rv$data
    req(data_kpi, "qualite_isolation_enveloppe" %in% names(data_kpi))
    
    nb_tres_bonne = data_kpi %>%
      filter(qualite_isolation_enveloppe == "très bonne") %>%
      nrow()
    
    pourcentage = if(nrow(data_kpi) > 0) {
      round((nb_tres_bonne / nrow(data_kpi)) * 100, 1)
    } else { 0 }
    
    valueBox(
      value = paste0(pourcentage, "%"),
      subtitle = "Isolation très bonne",
      icon = icon("shield-alt"),
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
    p = data_filtered %>%
      count(etiquette_dpe) %>%
      mutate(etiquette_dpe = factor(etiquette_dpe, levels = c("A", "B", "C", "D", "E", "F", "G", "Vierge"))) %>%
      ggplot(aes(x = etiquette_dpe, y = n, fill = etiquette_dpe)) +
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
    
    if(input$filter_outliers_cout) {
      # Filtrer les extrêmes
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
    
    ggplotly(p) %>% 
      layout(showlegend = FALSE)
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
    
    req(input$scatter_x %in% names(data_filtered),
        input$scatter_y %in% names(data_filtered))
    
    data_clean = data_filtered %>%
      filter(is.finite(!!sym(input$scatter_x)) & 
               is.finite(!!sym(input$scatter_y)))
    
    if(nrow(data_clean) < 2) {
      return("Corrélation : Non calculable")
    }
    
    correlation = cor(data_clean[[input$scatter_x]], 
                       data_clean[[input$scatter_y]], 
                       use = "complete.obs")
    
    paste("Coefficient de corrélation (r) :", round(correlation, 3))
  })
  
  # Graphique nuage de points (sans intervalle de confiance)
  output$plot_nuage_points = renderPlotly({
    
    if(is.null(input$scatter_x) || is.null(input$scatter_y) ||
       input$scatter_x == "" || input$scatter_y == "") {
      return(
        plotly_empty() %>% 
          layout(
            title = list(
              text = "Veuillez sélectionner les variables X et Y",
              font = list(size = 16, color = "#777")
            ),
            xaxis = list(showgrid = FALSE, showticklabels = FALSE),
            yaxis = list(showgrid = FALSE, showticklabels = FALSE)
          )
      )
    }
    
    data_filtered = rv$data
    
    req(input$scatter_x %in% names(data_filtered),
        input$scatter_y %in% names(data_filtered))
    
    data_clean = data_filtered %>%
      filter(is.finite(!!sym(input$scatter_x)) & 
               is.finite(!!sym(input$scatter_y)))
    
    if(nrow(data_clean) == 0) {
      return(plotly_empty() %>% 
               layout(title = "Aucune donnée valide"))
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
    
    ggplotly(p) %>%
      layout(showlegend = FALSE)
  })
  
  # OUTPUTS pour la page Contexte
  
  # Période des données
  output$periode_data = renderText({
    dates = as.Date(rv$data$date_etablissement_dpe)
    min_date = min(dates, na.rm = TRUE)
    max_date = max(dates, na.rm = TRUE)
    paste(format(min_date, "%d/%m/%Y"), "au", format(max_date, "%d/%m/%Y"))
  })
  
  # Nombre total de DPE
  output$nombre_total_dpe = renderText({
    format(nrow(rv$data), big.mark = " ")
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
