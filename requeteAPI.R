library(httr)
library(jsonlite)
library(dplyr)

<<<<<<< HEAD
setwd("~/cartable/U1/R Shiny/R-Shiny-DPE-Projet")
=======
adr69=unique(read.csv("adresses-69.csv",sep = ";",dec = ".")["code_postal"])
rownames(adr69)=NULL
>>>>>>> parent of f34363d (/update la BDD contient mtn la région complète et y un gitignore pour éviter de mettre n'importe quoi sur GitHub)

# --- Paramètres inchangés ---
code_departement = c("01", "03", "07", "15", "26", "38", "42", "43", "63", "69")

<<<<<<< HEAD
ls_base_url = c("https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines",
                "https://data.ademe.fr/data-fair/api/v1/datasets/dpe02neuf/lines")

select_fields = "numero_dpe,date_etablissement_dpe,etiquette_dpe,type_batiment,surface_habitable_logement,classe_inertie_batiment,adresse_ban,code_postal_ban,code_insee_ban,code_region_ban,code_departement_ban,coordonnee_cartographique_x_ban,coordonnee_cartographique_y_ban,deperditions_enveloppe,qualite_isolation_enveloppe,conso_5_usages_ep,conso_5_usages_par_m2_ep,type_energie_n1,cout_total_5_usages,type_energie_principale_chauffage"

annee_debut = 2021
annee_fin = 2025
MAX_SIZE = 10000 # Taille maximale de page
cpt = 0

# Initialisation du DataFrame principal
df = data.frame(numero_dpe = character(), date_etablissement_dpe = character(), etiquette_dpe = character(),
                type_batiment = character(), periode_construction = character(), surface_habitable_logement = numeric(),
                classe_inertie_batiment = character(), adresse_ban = character(), code_postal_ban = character(),
                code_insee_ban = character(), code_region_ban = character(), code_departement_ban = character(), coordonnee_cartographique_x_ban = numeric(),
                coordonnee_cartographique_y_ban = numeric(), deperditions_enveloppe = numeric(),
                qualite_isolation_enveloppe = character(), conso_5_usages_ep = numeric(),
                conso_5_usages_par_m2_ep = numeric(), type_energie_n1 = character(),
                cout_total_5_usages = numeric(), type_energie_principale_chauffage = character(), stringsAsFactors = FALSE)
# --- Fin Paramètres inchangés ---


# Boucles principales
for (base_url in ls_base_url) {
  for (code_dep in code_departement) {
    for (annee in annee_debut:annee_fin) {
      for (mois in 1:12) {
        
        if (mois<10){
          date_debut = paste0(annee,"-0",mois,"-01")
        }
        else{
          date_debut = paste0(annee,"-",mois,"-01")
        }
        
        if (mois==12){
          date_fin = paste0(annee+1,"-01-01")
        }
        else if (mois+1<10){
          date_fin = paste0(annee,"-0",mois+1,"-01")
        }
        else{
          date_fin = paste0(annee,"-",mois+1,"-01")
        }
        
        # Construction du query_string
        query_string = paste0('code_departement_ban:', code_dep,
                              ' AND date_etablissement_dpe:[', date_debut, ' TO ', date_fin, ']')
        
        # Paramètres de la requête (incluant la page actuelle)
        params = list(
          size = MAX_SIZE,
          select = select_fields,
          qs = query_string
        )
          
        # Exécution de la requête
        response = GET(modify_url(base_url, query = params))

        temp_data = fromJSON(rawToChar(response$content), flatten = FALSE)
        temp_df = temp_data$result
        nb_rows = ifelse(is.null(nrow(temp_df)), 0, nrow(temp_df))
        
        if (nb_rows==MAX_SIZE){
          print("\n\n\nATTENTION DANGER\n")
        }
        
        cpt = cpt + nb_rows
          
        print(paste("Dep :", code_dep, "| Année:", annee, "| Mois:", mois," : ",nb_rows, "lignes (Total:", cpt, ")"))
            
        # Ajout des données au DataFrame principal
        if (!is.null(nrow(temp_df)) && nrow(temp_df) > 0) {
          df <- dplyr::bind_rows(df, temp_df)
        }
        
        Sys.sleep(0.1) # Pause entre les requêtes pour ne pas surcharger le serveur
      
      }
    }
  }
}

# Assurez-vous que toutes les colonnes sont correctement définies avant l'écriture
# R utilise souvent la virgule pour la séparation, et le point pour la décimale
write.csv(df, "BaseDeDonnes.csv", row.names = FALSE)

for (dep in code_departement){
  write.csv(df[df$code_departement_ban==dep,], paste0("BaseDeDonnes",dep,".csv"), row.names = FALSE)
}

=======
df=data.frame()

for (i in 1:nrow(adr69)){
  for (j in 2021:2025){
    for (k in 1:2){ 
      if (k == 1) {
        date_debut <- paste0(j, "-01-01") # S1: 1er janvier
        date_fin <- paste0(j, "-06-30")   # S1: 30 juin
      } else {
        date_debut <- paste0(j, "-07-01") # S2: 1er juillet
        date_fin <- paste0(j, "-12-31")   # S2: 31 décembre
      }
      
      # Paramètres de la requête
      params <- list(
        page = 1,
        size = 10000,
        select = select_fields,
        qs = paste0(
                    'code_postal_ban:', as.character(adr69[i, 1]),
                    ' AND date_etablissement_dpe:[', date_debut, ' TO ', date_fin, ']'
                  )
      ) 
      
      temp_df <- fromJSON(rawToChar(GET(modify_url(base_url, query = params))$content), flatten = FALSE)$result
      
      print(paste(i,',',j,'-S',k))
      
      df= dplyr::bind_rows(df,temp_df)
      Sys.sleep(0.1)
    }
  }
}
>>>>>>> parent of f34363d (/update la BDD contient mtn la région complète et y un gitignore pour éviter de mettre n'importe quoi sur GitHub)
