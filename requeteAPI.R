library(httr)
library(jsonlite)
library(dplyr)

adr69=unique(read.csv("adresses-69.csv",sep = ";",dec = ".")["code_postal"])
rownames(adr69)=NULL

base_url = "https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines"
select_fields = "numero_dpe,date_etablissement_dpe,etiquette_dpe,type_batiment,periode_construction,surface_habitable_logement,classe_inertie_batiment,adresse_ban,code_postal_ban,code_insee_ban,code_region_ban,coordonnee_cartographique_x_ban,coordonnee_cartographique_y_ban,deperditions_enveloppe,qualite_isolation_enveloppe,conso_5_usages_ep,conso_5_usages_par_m2_ep,type_energie_n1,cout_total_5_usages,type_energie_principale_chauffage"

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
