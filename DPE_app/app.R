library(shiny)
library(bslib)
library(leaflet)
library(ggplot2)
library(DT)
library(dplyr)

#install.packages(c("shiny","bslib","leaflet","ggplot", "DT", "dplyr"))
setwd("~/cartable/U1/R Shiny/R-Shiny-DPE-Projet")


extract_data = function(){
  df = data.frame()
  dept = c("01", "38", "69")
  dept = c("01")
  for (i in dept) {
    temp = read.csv(paste0("BaseDeDonnée\\BaseDeDonnes",i,".csv"))
    df = rbind(df,temp)
  }
  
  return(df)
}

table_data_originel=extract_data()
table_data=table_data_originel


mon_theme = bslib::bs_theme(
  bootswatch = "flatly",
  base_font = font_google("Inter"),
  bg = "#FFFFFF", 
  fg = "#343A40"
)

ui = navbarPage(
  title = "Titre de l'Application",

  theme = mon_theme,
  
  header = tagList(
    #bs_theme_toggle(), 
    tags$div(style = "padding-right: 15px;") 
  ),
  
  # Premier onglet
  tabPanel(
    "Graphique", 
    h3("Affichage des graphs"),
    dataTableOutput("data_table")
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
             uiOutput("code_departement_ui"),
             uiOutput("type_energie_n1_ui"),
             uiOutput("type_chaffage_ui")
      )
    )
  ),
  
  # Cinquième onglet
  tabPanel(
    "Contexte", 
    h3("Page qui explique le contexte"),
    p("Ceci est l'onglet du contexte de l'application")
  ),
)

server = function(input, output) {
  
  rv = reactiveValues(data = table_data)
  
  output$ma_carte = renderLeaflet({
    data_map = subset(subset(rv$data,coordonnee_cartographique_x_ban!=0)$coordonnee_cartographique_x_ban, subset(table_data,coordonnee_cartographique_y_ban!=0)$coordonnee_cartographique_y_ban)
    leaflet(data_map) %>%
      addTiles() %>%
      addMarkers(~coordonnee_cartographique_x_ban, ~coordonnee_cartographique_y_ban, clusterOptions = markerClusterOptions())
  })
  
  # Rendu du tableau de données
  output$data_table = renderDT({
    datatable(
      rv$data, 
      options = list(
        scrollX = TRUE, 
        scrollCollapse = TRUE,
        dom = 'tip', 
        filter = 'top' 
      )
    )
  })
  
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
  
  # 2. Surface
  output$surface_habitable_ui = renderUI({
    
    surfaces = table_data$surface_habitable_logement
    
    # S'assurer que les bornes ne sont pas NA
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
  
  # 1. ÉTIQUETTE DPE
  output$etiquette_dpe_ui = renderUI({
    selectInput(
      "filtre_etiquette_dpe",
      label = "Étiquette DPE :",
      # trier (sort) les choix pour une meilleure lisibilité
      choices = sort(unique(table_data$etiquette_dpe)),
      multiple = TRUE
    )
  })
  
  # 2. TYPE BÂTIMENT
  output$type_batiment_ui = renderUI({
    selectInput(
      "filtre_type_batiment",
      label = "Type de bâtiment :",
      choices = sort(unique(table_data$type_batiment)),
      multiple = TRUE
    )
  })
  
  # 3. CLASSE INERTIE
  output$classe_inertie_ui = renderUI({
    selectInput(
      "filtre_classe_inertie",
      label = "Classe d'inertie du bâtiment :",
      choices = sort(unique(table_data$classe_inertie_batiment)),
      multiple = TRUE
    )
  })
  
  # 4. CODE DÉPARTEMENT
  output$code_departement_ui = renderUI({
    selectInput(
      "filtre_code_departement",
      label = "Code département :",
      choices = sort(unique(table_data$code_departement_ban)),
      multiple = TRUE
    )
  })
  
  # 5. TYPE ÉNERGIE N1
  output$type_energie_n1_ui = renderUI({
    selectInput(
      "filtre_type_energie_n1",
      label = "Type d'énergie N1 :",
      choices = sort(unique(table_data$type_energie_n1)),
      multiple = TRUE
    )
  })
  
  # 6. ÉNERGIE CHAUFFAGE
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
  
}

# Run the application 
shinyApp(ui = ui, server = server)
