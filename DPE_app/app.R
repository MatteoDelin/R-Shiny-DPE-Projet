library(shiny)
library(bslib)

mon_theme <- bs_theme(
  bootswatch = "flatly",
  base_font = font_google("Inter"),
  bg = "#FFFFFF", 
  fg = "#343A40"
)

ui <- navbarPage(
  title = "Titre de l'Application",

  theme = mon_theme,
  
  header = tagList(
    #bs_theme_toggle(), 
    tags$div(style = "padding-right: 15px;") 
  ),
  
  # Premier onglet
  tabPanel(
    "Accueil", 
    h3("Bienvenue sur l'Accueil"),
    p("Ceci est l'onglet principal de la navigation.")
  ),
  
  # Deuxième onglet
  tabPanel(
    "Cartographie", 
    sidebarLayout(
      sidebarPanel(
        sliderInput("bins", "Nombre de bins:", 1, 50, 30)
      ),
      mainPanel(
        plotOutput("distPlot")
      )
    )
  ),
  
  # Troisième onglet
  tabPanel(
    "Tableaux", 
    h3("Affichage de données"),
    dataTableOutput("data_table")
  ),
  
  # Quatrième onglet
  tabPanel(
    "Graphique", 
    h3("Affichage des graphs"),
    dataTableOutput("data_table")
  ),
  
  # Cinquième onglet
  tabPanel(
    "Contexte", 
    h3("Page qui explique le contexte"),
    p("Ceci est l'onglet du contexte de l'application")
  ),
)

server <- function(input, output) {

}

# Run the application 
shinyApp(ui = ui, server = server)
