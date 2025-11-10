library(httr)
library(jsonlite)
library(dplyr)

refresh_api = function(date_derniere_maj) {
  code_departement = c("01")
  
  ls_base_url = c("https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines",
                  "https://data.ademe.fr/data-fair/api/v1/datasets/dpe02neuf/lines")
  
  select_fields = "numero_dpe,date_etablissement_dpe,etiquette_dpe,type_batiment,periode_construction,surface_habitable_logement,classe_inertie_batiment,adresse_ban,code_postal_ban,code_insee_ban,code_region_ban,code_departement_ban,coordonnee_cartographique_x_ban,coordonnee_cartographique_y_ban,deperditions_enveloppe,qualite_isolation_enveloppe,conso_5_usages_ep,conso_5_usages_par_m2_ep,type_energie_n1,cout_total_5_usages,type_energie_principale_chauffage"
  
  date_debut = as.Date(date_derniere_maj)
  date_fin = Sys.Date()
  
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
      while(date_debut<date_fin){
        annee=year(date_debut)
        mois=month(date_debut)
        
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
        
        temp_data = fromJSON(rawToChar(response$content), flatten = FALSE)
        temp_df = temp_data$result
        nb_rows = ifelse(is.null(nrow(temp_df)), 0, nrow(temp_df))
        
        print(paste0(date_debut," TO ",date_fin_mois," : ",nb_rows,"lignes suplémentaire"))
        
        # Ajout des données au DataFrame principal
        if (!is.null(nrow(temp_df)) && nrow(temp_df) > 0) {
          df = dplyr::bind_rows(df, temp_df)
        }
        
        if (mois==12){
          date_debut=paste0(annee+1,"-01-01")
        }
        else{
          date_debut=paste0(annee,"-",mois+1,"-01")
        }
        
        if (mois==12){
          date_fin_mois=paste0(annee+1,"-02-01")
        }
        else{
          date_fin_mois=paste0(annee,"-",mois+2,"-01")
        }
        
        
        Sys.sleep(0.1) # Pause entre les requêtes pour ne pas surcharger le serveur
      }
    }
  }
  df$`_score` = NULL
  return(df)
}

df=refresh_api("2021-07-01")
# Assurez-vous que toutes les colonnes sont correctement définies avant l'écriture
# R utilise souvent la virgule pour la séparation, et le point pour la décimale
write.csv(df, "BaseDeDonnes.csv", row.names = FALSE)


